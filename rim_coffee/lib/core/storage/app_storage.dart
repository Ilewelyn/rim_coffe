import 'package:flutter/foundation.dart';
import 'package:rim_coffee/core/storage/motor_datos.dart';
import 'package:rim_coffee/core/storage/motor_preferencias.dart';
import 'package:rim_coffee/core/storage/motor_sqlite.dart';

/// Acceso a los datos de la app.
///
/// En Android los datos viven en una base de datos **SQLite**
/// (`rim_coffee.db`, ver `esquema.dart`) con tablas para negocio, usuarios,
/// mesas, categorías, productos, cuentas, pedidos y sus productos.
/// Al arrancar se cargan a memoria, así las pantallas leen al instante;
/// cada cambio se escribe en la base en segundo plano, en orden y dentro
/// de una transacción.
class AppStorage {
  AppStorage._();

  static MotorDatos _motor = MotorMemoria();
  static Map<String, String> _cache = {};
  static Future<void> _cola = Future<void>.value();

  /// Aviso de cada cambio local (lo usa la sincronización con la nube).
  static void Function(String clave)? alEscribir;

  /// Nombre del motor en uso (se muestra en Panel → Seguridad).
  static String get motor => _motor.nombre;

  /// Abre la base de datos (o el almacenamiento local en web) y carga todo.
  static Future<void> init() async {
    final preferencias = await MotorPreferencias.abrir();
    MotorDatos motor = preferencias;
    try {
      final sqlite = await abrirMotorSqlite(anteriores: preferencias.cargar);
      if (sqlite != null) {
        motor = sqlite;
      }
    } catch (e) {
      debugPrint('No se pudo abrir SQLite, se usa almacenamiento local: $e');
    }
    _motor = motor;
    _cache = await motor.cargar();
    _cola = Future<void>.value();
  }

  /// Sin disco: solo para pruebas automáticas.
  static Future<void> initMemoria() async {
    _motor = MotorMemoria();
    _cache = {};
    _cola = Future<void>.value();
  }

  /// Espera a que terminen las escrituras pendientes.
  static Future<void> esperarEscrituras() => _cola;

  static void _encolar(Future<void> Function() tarea) {
    _cola = _cola.then((_) => tarea()).catchError((Object e) {
      debugPrint('Error al guardar en la base de datos: $e');
    });
  }

  static String? leer(String clave) => _cache[clave];

  static void escribir(String clave, String valor) {
    if (_cache[clave] == valor) {
      return;
    }
    _cache[clave] = valor;
    _encolar(() => _motor.escribir(clave, valor));
    alEscribir?.call(clave);
  }

  /// Guarda un dato que llegó de la nube (no se vuelve a subir).
  static void escribirDesdeNube(String clave, String valor) {
    if (_cache[clave] == valor) {
      return;
    }
    _cache[clave] = valor;
    _encolar(() => _motor.escribir(clave, valor));
  }

  static void borrar(String clave) {
    if (_cache.remove(clave) == null) {
      return;
    }
    _encolar(() => _motor.borrar(clave));
  }

  /// Copia de todo lo que guarda la app (para el respaldo).
  static Map<String, String> exportar() {
    return {
      for (final e in _cache.entries)
        if (e.key.startsWith('rc.')) e.key: e.value,
    };
  }

  /// Borra todo lo de la app y escribe [datos] (importar un respaldo).
  static void reemplazarTodo(Map<String, String> datos) {
    borrarTodo();
    datos.forEach(escribir);
  }

  /// Borra todo lo que guarda la app (deja el dispositivo como recién instalado).
  static void borrarTodo() {
    _cache = {};
    _encolar(_motor.borrarTodo);
  }

  /// Filas por tabla de la base de datos (vacío si no hay tablas).
  static Future<Map<String, int>> conteoTablas() async {
    await _cola;
    return _motor.conteo();
  }
}
