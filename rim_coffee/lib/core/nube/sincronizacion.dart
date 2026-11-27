import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rim_coffee/core/nube/nube.dart';
import 'package:rim_coffee/core/storage/app_storage.dart';
import 'package:rim_coffee/core/storage/esquema.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Estado visible de la sincronización.
enum EstadoNube { apagada, sincronizando, alDia, pendiente, sinConexion }

/// Conversión entre filas locales (SQLite) y filas de la nube (PostgreSQL).
/// En la nube los booleanos son `boolean` y cada fila lleva `negocio_id`.
class FilaNube {
  FilaNube._();

  static Set<String> _booleanas(Tabla t) =>
      {for (final c in t.columnas) if (c.tipo == TipoCol.booleano) c.nombre};

  static Set<String> _reales(Tabla t) =>
      {for (final c in t.columnas) if (c.tipo == TipoCol.real) c.nombre};

  /// Columnas que una fila local tiene (las de la tabla, `orden` y `extra`).
  static List<String> columnasLocales(Tabla t) => [
        for (final c in t.columnas) c.nombre,
        if (t.ordenada) 'orden',
        'extra',
      ];

  static Map<String, Object?> aNube(Tabla t, Map<String, Object?> local, String uid) {
    final bools = _booleanas(t);
    final fila = <String, Object?>{'negocio_id': uid};
    for (final col in columnasLocales(t)) {
      final v = local[col];
      fila[col] = bools.contains(col) && v != null ? (v == 1 || v == true) : v;
    }
    return fila;
  }

  static Map<String, Object?> desdeNube(Tabla t, Map<String, dynamic> nube) {
    final bools = _booleanas(t);
    final reales = _reales(t);
    final fila = <String, Object?>{};
    for (final col in columnasLocales(t)) {
      final v = nube[col];
      if (v == null) {
        fila[col] = null;
      } else if (bools.contains(col)) {
        fila[col] = v == true ? 1 : 0;
      } else if (reales.contains(col) && v is num) {
        fila[col] = v.toDouble();
      } else if (v is num && col != 'orden' && !reales.contains(col)) {
        fila[col] = v.toInt();
      } else {
        fila[col] = v;
      }
    }
    return fila;
  }

  static String firma(Map<String, Object?> fila) =>
      jsonEncode(SplayTreeMap<String, Object?>.from(fila));
}

/// Mantiene la base local (SQLite) y la nube (Supabase) iguales.
///
/// - Cada cambio local se sube en segundo plano: solo las filas nuevas,
///   cambiadas o borradas.
/// - Los cambios de otros dispositivos llegan al momento (Realtime) y,
///   por si acaso, se revisa la nube cada 30 segundos y al volver a la app.
/// - Sin internet todo sigue funcionando con la base local; lo pendiente
///   se sube al volver la conexión.
class Sincronizacion with WidgetsBindingObserver {
  Sincronizacion._();

  static final Sincronizacion instance = Sincronizacion._();

  /// Datos que se comparten entre dispositivos. El turno, la sesión, el
  /// modo Cliente y el carrito son de cada dispositivo.
  static const List<String> claves = [
    Esquema.kNegocio,
    Esquema.kUsuarios,
    Esquema.kConfig,
    Esquema.kProductos,
    Esquema.kCuentas,
    Esquema.kPedidos,
  ];

  static const String _kPendientes = 'rc.nube.pendientes';
  static const int _lote = 500;

  final ValueNotifier<EstadoNube> estado = ValueNotifier(EstadoNube.apagada);
  final ValueNotifier<DateTime?> ultimaVez = ValueNotifier(null);

  /// Se llama con las claves que cambiaron desde otro dispositivo.
  void Function(Set<String> claves)? alCambiarDesdeNube;

  final Map<String, Map<String, Map<String, Object?>>> _base = {};
  final Set<String> _pendientes = {};
  final Set<String> _porBajar = {};
  bool _activa = false;
  bool _ocupada = false;
  bool _otraVuelta = false;
  Timer? _reloj;
  Timer? _espera;
  RealtimeChannel? _canal;

  bool get activa => _activa;

  // ------------------------------------------------------------ ciclo

  /// Empieza a sincronizar (con sesión iniciada en la nube).
  Future<void> iniciar() async {
    if (_activa || !Nube.haySesion) {
      return;
    }
    _activa = true;
    final guardadas = AppStorage.leer(_kPendientes);
    if (guardadas != null) {
      _pendientes.addAll((jsonDecode(guardadas) as List<dynamic>).cast<String>());
    }
    WidgetsBinding.instance.addObserver(this);
    _suscribir();
    _reloj = Timer.periodic(const Duration(seconds: 30), (_) => sincronizarAhora());
    await sincronizarAhora();
  }

  Future<void> detener() async {
    _activa = false;
    _reloj?.cancel();
    _espera?.cancel();
    _reloj = null;
    _espera = null;
    final canal = _canal;
    _canal = null;
    if (canal != null) {
      try {
        await Nube.cliente.removeChannel(canal);
      } catch (_) {}
    }
    WidgetsBinding.instance.removeObserver(this);
    _base.clear();
    _pendientes.clear();
    _porBajar.clear();
    estado.value = EstadoNube.apagada;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _activa) {
      sincronizarAhora();
    }
  }

  void _suscribir() {
    final uid = Nube.uid;
    if (uid == null) {
      return;
    }
    var canal = Nube.cliente.channel('rc-$uid');
    for (final clave in claves) {
      for (final t in Esquema.tablasPorClave[clave]!) {
        canal = canal.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: t.nombre,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'negocio_id',
            value: uid,
          ),
          callback: (_) => _programarBajada(clave),
        );
      }
    }
    _canal = canal.subscribe();
  }

  void _programarBajada(String clave) {
    _porBajar.add(clave);
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 700), () {
      final lista = Set<String>.of(_porBajar);
      _porBajar.clear();
      _vuelta(bajar: lista);
    });
  }

  // ------------------------------------------------------------ escrituras locales

  /// AppStorage avisa aquí cada vez que cambia un dato local.
  void alEscribirLocal(String clave) {
    if (!_activa || !claves.contains(clave)) {
      return;
    }
    _pendientes.add(clave);
    _guardarPendientes();
    estado.value = EstadoNube.pendiente;
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), () {
      final lista = Set<String>.of(_porBajar);
      _porBajar.clear();
      _vuelta(bajar: lista);
    });
  }

  void _guardarPendientes() {
    AppStorage.escribirDesdeNube(_kPendientes, jsonEncode(_pendientes.toList()));
  }

  /// Sube lo pendiente y baja todo lo de la nube.
  Future<void> sincronizarAhora() => _vuelta(bajar: claves.toSet());

  Future<void> _vuelta({required Set<String> bajar}) async {
    if (!_activa) {
      return;
    }
    if (_ocupada) {
      _otraVuelta = true;
      _porBajar.addAll(bajar);
      return;
    }
    _ocupada = true;
    estado.value = EstadoNube.sincronizando;
    try {
      await _subirPendientes();
      if (bajar.isNotEmpty) {
        await _bajar(bajar);
      }
      ultimaVez.value = DateTime.now();
      estado.value = _pendientes.isEmpty ? EstadoNube.alDia : EstadoNube.pendiente;
    } catch (e) {
      debugPrint('Sincronización: $e');
      estado.value = EstadoNube.sinConexion;
    } finally {
      _ocupada = false;
    }
    if (_otraVuelta && _activa) {
      _otraVuelta = false;
      final lista = Set<String>.of(_porBajar);
      _porBajar.clear();
      await _vuelta(bajar: lista);
    }
  }

  // ------------------------------------------------------------ subir

  Future<void> _subirPendientes() async {
    for (final clave in List<String>.of(_pendientes)) {
      final valor = AppStorage.leer(clave);
      if (valor != null && valor != 'null') {
        await _subir(clave, valor);
      }
      _pendientes.remove(clave);
      _guardarPendientes();
    }
  }

  Future<void> _subir(String clave, String valor) async {
    final uid = Nube.uid;
    if (uid == null) {
      throw StateError('Sin sesión');
    }
    final nuevas = Esquema.aTablas(clave, valor);
    final tablas = Esquema.tablasPorClave[clave]!;

    // Primero se suben las filas (padres antes que hijos) y después se
    // borran las que ya no existen (hijos antes que padres).
    final borrar = <Tabla, List<Map<String, Object?>>>{};
    final ahoraPorTabla = <String, Map<String, Map<String, Object?>>>{};
    for (final t in tablas) {
      final antes = _base[t.nombre];
      final ahora = <String, Map<String, Object?>>{
        for (final f in nuevas[t.nombre] ?? const <Map<String, Object?>>[]) t.llaveDe(f): f,
      };
      ahoraPorTabla[t.nombre] = ahora;
      final cambiadas = [
        for (final e in ahora.entries)
          if (antes == null || FilaNube.firma(antes[e.key] ?? const {}) != FilaNube.firma(e.value))
            FilaNube.aNube(t, e.value, uid),
      ];
      for (var i = 0; i < cambiadas.length; i += _lote) {
        final fin = i + _lote > cambiadas.length ? cambiadas.length : i + _lote;
        await Nube.cliente.from(t.nombre).upsert(cambiadas.sublist(i, fin));
      }
      if (antes != null) {
        borrar[t] = [
          for (final e in antes.entries)
            if (!ahora.containsKey(e.key)) e.value,
        ];
      }
    }
    for (final t in tablas.reversed) {
      final filas = borrar[t] ?? const [];
      for (final f in filas) {
        var consulta = Nube.cliente.from(t.nombre).delete().eq('negocio_id', uid);
        for (final k in t.llave) {
          consulta = consulta.eq(k, f[k] as Object);
        }
        await consulta;
      }
    }
    for (final t in tablas) {
      _base[t.nombre] = ahoraPorTabla[t.nombre]!;
    }
  }

  // ------------------------------------------------------------ bajar

  Future<List<Map<String, dynamic>>> _leerTabla(Tabla t, String uid) async {
    final filas = <Map<String, dynamic>>[];
    const pagina = 1000;
    var desde = 0;
    while (true) {
      final r = await Nube.cliente
          .from(t.nombre)
          .select()
          .eq('negocio_id', uid)
          .order(t.ordenada ? 'orden' : t.llave.first)
          .order(t.llave.last)
          .range(desde, desde + pagina - 1);
      filas.addAll(r);
      if (r.length < pagina) {
        break;
      }
      desde += pagina;
    }
    return filas;
  }

  /// Baja de la nube las claves indicadas. Devuelve las que cambiaron.
  Future<Set<String>> _bajar(Set<String> lista, {bool avisar = true}) async {
    final uid = Nube.uid;
    if (uid == null) {
      return {};
    }
    final cambiadas = <String>{};
    for (final clave in claves) {
      if (!lista.contains(clave) || _pendientes.contains(clave)) {
        continue;
      }
      final filas = <String, List<Map<String, Object?>>>{};
      final base = <String, Map<String, Map<String, Object?>>>{};
      for (final t in Esquema.tablasPorClave[clave]!) {
        final locales = [for (final f in await _leerTabla(t, uid)) FilaNube.desdeNube(t, f)];
        filas[t.nombre] = locales;
        base[t.nombre] = {for (final f in locales) t.llaveDe(f): f};
      }
      final principal = Esquema.tablasPorClave[clave]!.first.nombre;
      final vacia = filas[principal]!.isEmpty;
      if (vacia && (clave == Esquema.kNegocio || clave == Esquema.kConfig)) {
        continue;
      }
      // Si mientras bajaba hubo un cambio local, gana el local.
      if (_pendientes.contains(clave)) {
        continue;
      }
      _base.addAll(base);
      final json = Esquema.desdeTablas(clave, filas);
      if (AppStorage.leer(clave) != json) {
        AppStorage.escribirDesdeNube(clave, json);
        cambiadas.add(clave);
      }
    }
    if (avisar && cambiadas.isNotEmpty) {
      alCambiarDesdeNube?.call(cambiadas);
    }
    return cambiadas;
  }

  // ------------------------------------------------------------ al entrar

  /// True si la cuenta ya tiene un negocio guardado en la nube.
  Future<bool> hayNegocioEnNube() async {
    final uid = Nube.uid;
    if (uid == null) {
      return false;
    }
    final r = await Nube.cliente.from('negocio').select('id').eq('negocio_id', uid).limit(1);
    return r.isNotEmpty;
  }

  /// Este dispositivo se une a un negocio que ya está en la nube: baja
  /// todos sus datos y reemplaza los locales.
  Future<void> descargarTodo() async {
    _base.clear();
    _pendientes.clear();
    _guardarPendientes();
    await _bajar(claves.toSet(), avisar: false);
  }

  /// Deja todos los datos marcados para subir en cuanto haya conexión.
  void marcarTodoPendiente() {
    _base.clear();
    for (final clave in claves) {
      final valor = AppStorage.leer(clave);
      if (valor != null && valor != 'null') {
        _pendientes.add(clave);
      }
    }
    _guardarPendientes();
  }

  /// Sube todos los datos locales (negocio nuevo o que venía de una
  /// versión sin nube).
  Future<void> subirTodo() async {
    _base.clear();
    for (final clave in claves) {
      final valor = AppStorage.leer(clave);
      if (valor != null && valor != 'null') {
        await _subir(clave, valor);
      }
    }
    _pendientes.clear();
    _guardarPendientes();
  }
}
