import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rim_coffee/core/models/negocio.dart';
import 'package:rim_coffee/core/models/usuario.dart';
import 'package:rim_coffee/core/storage/app_storage.dart';
import 'package:rim_coffee/core/utils/formato.dart';
import 'package:rim_coffee/core/utils/seguridad.dart';

/// Resultado de escribir un código.
enum ResultadoPin { correcto, incorrecto, bloqueado, sinPermiso }

/// Resultado de verificar un código: qué pasó y, si fue correcto, de quién es.
class VerificacionCodigo {
  const VerificacionCodigo(this.resultado, [this.usuario]);

  final ResultadoPin resultado;
  final Usuario? usuario;
}

/// Usuarios del negocio (beneficiarios y administradores), cada uno con su
/// propio código. También recuerda quién tiene el turno en la tablet
/// ([actual]) y bloquea el teclado 30 s tras 3 códigos incorrectos.
///
/// Los códigos son únicos dentro del negocio: con escribir el código la app
/// ya sabe quién es.
class UsuariosController extends ChangeNotifier {
  UsuariosController._();

  static final UsuariosController instance = UsuariosController._();

  static const String _kUsuarios = 'rc.v3.usuarios';
  static const String _kActual = 'rc.v3.turno';
  static const String _kPersonalAnterior = 'rc.v2.personal';

  static const int maxIntentos = 3;
  static const int segundosDeBloqueo = 30;

  List<Usuario> _items = [];
  String? _actualId;

  int _fallos = 0;
  DateTime? _bloqueadoHasta;

  List<Usuario> get todos => List.unmodifiable(_items);
  List<Usuario> get activos => _items.where((u) => u.activo).toList();
  List<Usuario> get bajas => _items.where((u) => !u.activo).toList();

  /// Quien tiene el turno en la tablet ahora mismo (null = pantalla de código).
  Usuario? get actual {
    final id = _actualId;
    if (id == null) {
      return null;
    }
    final u = porId(id);
    return (u != null && u.activo) ? u : null;
  }

  bool get hayBeneficiario => _items.any((u) => u.activo && u.esBeneficiario && u.tieneCodigo);

  /// True si quien tiene el turno puede hacer eso.
  bool actualPuede(Permiso permiso) => actual?.puede(permiso) ?? false;

  Usuario? porId(String id) {
    for (final u in _items) {
      if (u.id == id) {
        return u;
      }
    }
    return null;
  }

  Usuario? porNombre(String nombre) {
    final clave = normalizarNombre(nombre);
    for (final u in _items) {
      if (normalizarNombre(u.nombre) == clave) {
        return u;
      }
    }
    return null;
  }

  // ------------------------------------------------------------ carga

  /// Carga los usuarios. Si vienen de la versión anterior (dos PIN
  /// compartidos), crea un beneficiario con el PIN del dueño y un
  /// administrador "Mostrador" con el del personal.
  /// Vuelve a leer lo guardado (por ejemplo, cuando llegan cambios de
  /// otro dispositivo) y avisa a las pantallas.
  void recargar() {
    cargar();
    notifyListeners();
  }

  void cargar({Negocio? anterior}) {
    _fallos = 0;
    _bloqueadoHasta = null;
    final raw = AppStorage.leer(_kUsuarios);
    if (raw != null) {
      final lista = jsonDecode(raw) as List<dynamic>;
      _items = lista.map((e) => Usuario.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      _items = [];
      if (anterior != null) {
        _migrar(anterior);
      }
    }
    _actualId = AppStorage.leer(_kActual);
  }

  void _migrar(Negocio anterior) {
    final pinDueno = anterior.legacyPinDueno;
    final pinPersonal = anterior.legacyPinPersonal;
    if (pinDueno != null && pinDueno.isNotEmpty) {
      _items.add(_nuevo('Beneficiario', Rol.beneficiario, pinDueno));
    }
    if (pinPersonal != null && pinPersonal.isNotEmpty && pinPersonal != pinDueno) {
      _items.add(_nuevo('Mostrador', Rol.administrador, pinPersonal));
    }
    final rawPersonal = AppStorage.leer(_kPersonalAnterior);
    if (rawPersonal != null) {
      try {
        final lista = jsonDecode(rawPersonal) as List<dynamic>;
        for (final e in lista) {
          final m = e as Map<String, dynamic>;
          final nombre = m['nombre'] as String? ?? '';
          if (nombre.trim().isEmpty || porNombre(nombre) != null) {
            continue;
          }
          final u = _nuevo(nombre, Rol.administrador, null);
          u.activo = m['activo'] as bool? ?? true;
          _items.add(u);
        }
      } catch (_) {
        // Lista anterior dañada: se ignora.
      }
    }
    _guardar();
  }

  Usuario _nuevo(String nombre, Rol rol, String? codigo, {Set<Permiso>? permisos}) {
    final sal = Seguridad.nuevaSal();
    return Usuario(
      id: Seguridad.nuevoId(),
      nombre: capitalizarNombre(nombre),
      rol: rol,
      sal: sal,
      codigoHuella: codigo == null ? '' : Seguridad.huella(codigo.trim(), sal),
      codigoVisible: rol == Rol.administrador && codigo != null ? codigo.trim() : '',
      permisos: permisos,
    );
  }

  void _guardar() {
    AppStorage.escribir(_kUsuarios, jsonEncode(_items.map((u) => u.toJson()).toList()));
  }

  void _guardarActual() {
    final id = _actualId;
    if (id == null) {
      AppStorage.borrar(_kActual);
    } else {
      AppStorage.escribir(_kActual, id);
    }
  }

  // ------------------------------------------------------------ altas

  /// Busca a quien ya usa ese código (para no repetirlo).
  Usuario? _duenoDelCodigo(String codigo, {String? excepto}) {
    final c = codigo.trim();
    for (final u in _items) {
      if (u.id == excepto || !u.tieneCodigo) {
        continue;
      }
      if (Seguridad.coincide(c, u.sal, u.codigoHuella)) {
        return u;
      }
    }
    return null;
  }

  /// Da de alta a una persona. Devuelve un mensaje de error, o null si salió bien.
  String? crear({
    required String nombre,
    required Rol rol,
    required String codigo,
    Set<Permiso>? permisos,
  }) {
    final limpio = capitalizarNombre(nombre);
    if (limpio.isEmpty) {
      return 'Escribe el nombre';
    }
    final existente = porNombre(limpio);
    if (existente != null && existente.activo) {
      return 'Ya hay un usuario activo llamado ${existente.nombre}';
    }
    if (_duenoDelCodigo(codigo) != null) {
      return 'Ese código ya lo usa otra persona. Elige uno distinto.';
    }
    if (existente != null) {
      // Estaba dado de baja: se reactiva con sus datos nuevos.
      existente
        ..activo = true
        ..rol = rol
        ..permisos = {...?permisos}
        ..sal = Seguridad.nuevaSal();
      existente.codigoHuella = Seguridad.huella(codigo.trim(), existente.sal);
      existente.codigoVisible = rol == Rol.administrador ? codigo.trim() : '';
    } else {
      _items.add(_nuevo(limpio, rol, codigo, permisos: {...?permisos}));
    }
    _guardar();
    notifyListeners();
    return null;
  }

  /// Cambia nombre, rol o permisos. No deja al negocio sin beneficiario.
  String? editar(
    Usuario usuario, {
    String? nombre,
    Rol? rol,
    Set<Permiso>? permisos,
  }) {
    if (nombre != null) {
      final limpio = capitalizarNombre(nombre);
      if (limpio.isEmpty) {
        return 'Escribe el nombre';
      }
      final otro = porNombre(limpio);
      if (otro != null && otro.id != usuario.id) {
        return 'Ya hay un usuario llamado ${otro.nombre}';
      }
      usuario.nombre = limpio;
    }
    if (rol != null && rol != usuario.rol) {
      if (usuario.esBeneficiario && _beneficiariosActivos() <= 1) {
        return 'Debe quedar al menos un beneficiario.';
      }
      usuario.rol = rol;
      if (rol == Rol.beneficiario) {
        usuario.codigoVisible = '';
      }
    }
    if (permisos != null) {
      usuario.permisos = {...permisos};
    }
    _guardar();
    notifyListeners();
    return null;
  }

  int _beneficiariosActivos() =>
      _items.where((u) => u.activo && u.esBeneficiario).length;

  /// Pone un código nuevo. Si se da [actual], primero comprueba que sea el
  /// código de esa persona (cuando alguien cambia el suyo).
  String? cambiarCodigo(Usuario usuario, String nuevo, {String? actual}) {
    if (actual != null && !Seguridad.coincide(actual.trim(), usuario.sal, usuario.codigoHuella)) {
      return 'Tu código actual no es correcto.';
    }
    if (_duenoDelCodigo(nuevo, excepto: usuario.id) != null) {
      return 'Ese código ya lo usa otra persona. Elige uno distinto.';
    }
    usuario.sal = Seguridad.nuevaSal();
    usuario.codigoHuella = Seguridad.huella(nuevo.trim(), usuario.sal);
    usuario.codigoVisible = usuario.esBeneficiario ? '' : nuevo.trim();
    _guardar();
    notifyListeners();
    return null;
  }

  /// Baja: ya no puede entrar ni atender, pero sigue en los reportes.
  String? darDeBaja(Usuario usuario) {
    if (usuario.esBeneficiario && _beneficiariosActivos() <= 1) {
      return 'No puedes dar de baja al único beneficiario.';
    }
    usuario.activo = false;
    if (_actualId == usuario.id) {
      _actualId = null;
      _guardarActual();
    }
    _guardar();
    notifyListeners();
    return null;
  }

  void reactivar(Usuario usuario) {
    usuario.activo = true;
    _guardar();
    notifyListeners();
  }

  /// Deja solo al beneficiario indicado (al crear un negocio nuevo).
  void iniciarNegocio({required String nombre, required String codigo}) {
    _items = [_nuevo(nombre, Rol.beneficiario, codigo)];
    _actualId = _items.first.id;
    _fallos = 0;
    _bloqueadoHasta = null;
    _guardar();
    _guardarActual();
    notifyListeners();
  }

  /// Agrega el personal de ejemplo (Luis 1357 y Ana 1470) si sus códigos
  /// están libres. Lo usa "Restablecer datos de demostración".
  void agregarDemo() {
    const demo = {'Luis': '1357', 'Ana': '1470'};
    demo.forEach((nombre, codigo) {
      final u = porNombre(nombre);
      if (u != null) {
        u.activo = true;
        return;
      }
      if (_duenoDelCodigo(codigo) == null) {
        _items.add(_nuevo(nombre, Rol.administrador, codigo, permisos: {...permisosPorDefecto}));
      }
    });
    _guardar();
    notifyListeners();
  }

  // ------------------------------------------------------------ turno

  void iniciarTurno(Usuario usuario) {
    _actualId = usuario.id;
    _guardarActual();
    notifyListeners();
  }

  /// Bloquea la tablet: vuelve a pedirse un código.
  void cerrarTurno() {
    _actualId = null;
    _guardarActual();
    notifyListeners();
  }

  // ------------------------------------------------------------ códigos

  /// Segundos que faltan para que se desbloquee el teclado (0 si no está bloqueado).
  int get segundosBloqueo {
    final hasta = _bloqueadoHasta;
    if (hasta == null) {
      return 0;
    }
    final dif = hasta.difference(DateTime.now()).inSeconds + 1;
    if (dif <= 0) {
      _bloqueadoHasta = null;
      return 0;
    }
    return dif;
  }

  int get intentosRestantes => maxIntentos - _fallos;

  /// Comprueba un código y dice de quién es.
  ///
  /// - [soloBeneficiario]: solo vale el código de un beneficiario.
  /// - [permiso]: la persona debe tener ese permiso (el beneficiario siempre).
  ///
  /// Un código que no es de nadie cuenta como intento fallido; tras 3 el
  /// teclado se bloquea 30 segundos. Un código correcto sin permiso no
  /// cuenta como fallo.
  VerificacionCodigo verificar(
    String codigo, {
    bool soloBeneficiario = false,
    Permiso? permiso,
  }) {
    if (segundosBloqueo > 0) {
      return const VerificacionCodigo(ResultadoPin.bloqueado);
    }
    Usuario? encontrado;
    final texto = codigo.trim();
    if (texto.isNotEmpty) {
      for (final u in _items) {
        if (u.activo && u.tieneCodigo && Seguridad.coincide(texto, u.sal, u.codigoHuella)) {
          encontrado = u;
          break;
        }
      }
    }
    if (encontrado == null) {
      _fallos++;
      if (_fallos >= maxIntentos) {
        _fallos = 0;
        _bloqueadoHasta = DateTime.now().add(const Duration(seconds: segundosDeBloqueo));
        return const VerificacionCodigo(ResultadoPin.bloqueado);
      }
      return const VerificacionCodigo(ResultadoPin.incorrecto);
    }
    _fallos = 0;
    if (soloBeneficiario && !encontrado.esBeneficiario) {
      return VerificacionCodigo(ResultadoPin.sinPermiso, encontrado);
    }
    if (permiso != null && !encontrado.puede(permiso)) {
      return VerificacionCodigo(ResultadoPin.sinPermiso, encontrado);
    }
    return VerificacionCodigo(ResultadoPin.correcto, encontrado);
  }

  /// Borra todo (al borrar los datos del dispositivo).
  void olvidarTodo() {
    _items = [];
    _actualId = null;
    _fallos = 0;
    _bloqueadoHasta = null;
    AppStorage.borrar(_kUsuarios);
    AppStorage.borrar(_kActual);
    notifyListeners();
  }
}
