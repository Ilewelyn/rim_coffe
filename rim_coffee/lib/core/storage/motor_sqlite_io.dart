import 'dart:collection';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:rim_coffee/core/storage/esquema.dart';
import 'package:rim_coffee/core/storage/motor_datos.dart';
import 'package:sqflite/sqflite.dart';

/// Abre (o crea) la base de datos `rim_coffee.db`. La primera vez copia
/// a la base los datos de la versión anterior ([anteriores]).
Future<MotorDatos?> abrirMotorSqlite({
  required Future<Map<String, String>> Function() anteriores,
}) async {
  final motor = await MotorSqlite.abrir();
  if (!await motor.yaMigro()) {
    final datos = await anteriores();
    for (final e in datos.entries) {
      await motor.escribir(e.key, e.value);
    }
    await motor.marcarMigrado();
  }
  return motor;
}

/// Lo último que se guardó de una fila: su firma (para saber si cambió) y
/// los valores de su llave primaria (para poder borrarla).
class _Guardada {
  const _Guardada(this.firma, this.llave);

  final String firma;
  final List<Object?> llave;
}

/// Base de datos relacional SQLite (paquete `sqflite`).
///
/// Cada escritura compara con lo último guardado y solo toca las filas que
/// cambiaron (borrar, actualizar o insertar), todo dentro de una
/// transacción.
class MotorSqlite implements MotorDatos {
  MotorSqlite._(this._db);

  final Database _db;

  /// tabla → llave → fila guardada.
  final Map<String, Map<String, _Guardada>> _ultimas = {};

  static const String archivo = 'rim_coffee.db';
  static const String _kMigrado = '_migrado_preferencias';

  static Future<MotorSqlite> abrir() async {
    final ruta = p.join(await getDatabasesPath(), archivo);
    final db = await openDatabase(
      ruta,
      version: Esquema.version,
      onCreate: (db, version) async {
        final lote = db.batch();
        for (final t in Esquema.tablas) {
          lote.execute(t.sqlCrear);
        }
        for (final indice in Esquema.indices) {
          lote.execute(indice);
        }
        await lote.commit(noResult: true);
      },
    );
    return MotorSqlite._(db);
  }

  @override
  String get nombre => 'SQLite ($archivo)';

  static String _firma(Map<String, Object?> fila) =>
      jsonEncode(SplayTreeMap<String, Object?>.from(fila));

  @override
  Future<Map<String, String>> cargar() async {
    final filas = <String, List<Map<String, Object?>>>{};
    for (final t in Esquema.tablas) {
      final lista = await _db.query(t.nombre, orderBy: t.ordenSql);
      filas[t.nombre] = lista;
      _ultimas[t.nombre] = {
        for (final f in lista)
          t.llaveDe(f): _Guardada(_firma(f), [for (final k in t.llave) f[k]]),
      };
    }
    final datos = <String, String>{};
    final presentes = <String>{};
    for (final f in filas['ajustes'] ?? const <Map<String, Object?>>[]) {
      final clave = '${f['clave']}';
      final valor = f['valor'];
      if (clave.startsWith(Esquema.prefijoPresente)) {
        presentes.add(clave.substring(Esquema.prefijoPresente.length));
      } else if (clave.startsWith('rc.') && valor is String) {
        datos[clave] = valor;
      }
    }
    for (final clave in Esquema.tablasPorClave.keys) {
      if (presentes.contains(clave)) {
        datos[clave] = Esquema.desdeTablas(clave, filas);
      }
    }
    return datos;
  }

  /// True si ya se pasaron los datos de la versión anterior a la base.
  Future<bool> yaMigro() async {
    final r = await _db.query('ajustes', where: 'clave = ?', whereArgs: [_kMigrado]);
    return r.isNotEmpty;
  }

  Future<void> marcarMigrado() async {
    await _db.insert(
      'ajustes',
      {'clave': _kMigrado, 'valor': DateTime.now().toIso8601String(), 'extra': null},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _where(Tabla t) => t.llave.map((k) => '$k = ?').join(' AND ');

  @override
  Future<void> escribir(String clave, String valor) async {
    if (!Esquema.tieneTablas(clave)) {
      await _db.insert(
        'ajustes',
        {'clave': clave, 'valor': valor, 'extra': null},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return;
    }
    final nuevas = Esquema.aTablas(clave, valor);
    final tablas = Esquema.tablasPorClave[clave]!;
    final despues = <String, Map<String, _Guardada>>{};

    await _db.transaction((txn) async {
      final lote = txn.batch();
      for (final t in tablas) {
        final antes = _ultimas[t.nombre] ?? const <String, _Guardada>{};
        final ahora = <String, Map<String, Object?>>{};
        for (final fila in nuevas[t.nombre] ?? const <Map<String, Object?>>[]) {
          ahora[t.llaveDe(fila)] = fila;
        }
        final guardadas = <String, _Guardada>{};
        antes.forEach((llave, g) {
          if (!ahora.containsKey(llave)) {
            lote.delete(t.nombre, where: _where(t), whereArgs: g.llave);
          }
        });
        ahora.forEach((llave, fila) {
          final firma = _firma(fila);
          final valoresLlave = [for (final k in t.llave) fila[k]];
          if (antes[llave]?.firma != firma) {
            lote.insert(t.nombre, fila, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          guardadas[llave] = _Guardada(firma, valoresLlave);
        });
        despues[t.nombre] = guardadas;
      }
      lote.insert(
        'ajustes',
        {'clave': '${Esquema.prefijoPresente}$clave', 'valor': '1', 'extra': null},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await lote.commit(noResult: true);
    });
    _ultimas.addAll(despues);
  }

  @override
  Future<void> borrar(String clave) async {
    if (!Esquema.tieneTablas(clave)) {
      await _db.delete('ajustes', where: 'clave = ?', whereArgs: [clave]);
      return;
    }
    await _db.transaction((txn) async {
      for (final t in Esquema.tablasPorClave[clave]!) {
        await txn.delete(t.nombre);
        _ultimas[t.nombre] = {};
      }
      await txn.delete(
        'ajustes',
        where: 'clave = ?',
        whereArgs: ['${Esquema.prefijoPresente}$clave'],
      );
    });
  }

  @override
  Future<void> borrarTodo() async {
    await _db.transaction((txn) async {
      for (final t in Esquema.tablas) {
        if (t.nombre == 'ajustes') {
          await txn.delete('ajustes', where: 'clave <> ?', whereArgs: [_kMigrado]);
        } else {
          await txn.delete(t.nombre);
        }
        _ultimas[t.nombre] = {};
      }
    });
  }

  @override
  Future<Map<String, int>> conteo() async {
    final resultado = <String, int>{};
    for (final t in Esquema.tablas) {
      final r = await _db.rawQuery('SELECT COUNT(*) AS n FROM ${t.nombre}');
      resultado[t.nombre] = Sqflite.firstIntValue(r) ?? 0;
    }
    return resultado;
  }
}
