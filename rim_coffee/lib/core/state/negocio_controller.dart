import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rim_coffee/core/models/negocio.dart';
import 'package:rim_coffee/core/nube/nube.dart';
import 'package:rim_coffee/core/storage/app_storage.dart';
import 'package:rim_coffee/core/utils/seguridad.dart';

/// Datos de la cuenta del negocio en este dispositivo: nombre, eslogan,
/// logo y correo. La cuenta en sí (contraseña o Google) vive en la nube
/// (Supabase, ver `Nube`). La sesión se guarda: al volver a abrir la app se
/// entra directo a la pantalla de "¿Quién atiende?".
class NegocioController extends ChangeNotifier {
  NegocioController._();

  static final NegocioController instance = NegocioController._();

  static const String _kNegocio = 'rc.v2.negocio';
  static const String _kSesion = 'rc.v2.sesion';

  /// Nombre de la plataforma (cuando todavía no hay negocio registrado).
  static const String nombreApp = 'Rim Coffee';

  Negocio? negocio;
  bool sesionIniciada = false;
  bool _migrado = false;

  bool get existeCuenta => negocio != null;
  bool get estaAutenticado => negocio != null && sesionIniciada && Nube.haySesion;
  String get nombre => negocio?.nombre ?? nombreApp;
  String get correo => negocio?.correo ?? '';
  String get eslogan {
    final e = negocio?.eslogan ?? '';
    return e.isEmpty ? 'Café de especialidad, servido con calma.' : e;
  }

  String get logo => negocio?.logo ?? '';
  String get correoGoogle => negocio?.correoGoogle ?? '';

  /// Vuelve a leer lo guardado (por ejemplo, cuando llegan cambios de
  /// otro dispositivo) y avisa a las pantallas.
  void recargar() {
    cargar();
    notifyListeners();
  }

  void cargar() {
    final raw = AppStorage.leer(_kNegocio);
    negocio = raw == null
        ? null
        : Negocio.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    sesionIniciada = negocio != null && AppStorage.leer(_kSesion) == 'si';
    _migrado = false;
    final n = negocio;
    // Versión anterior: la contraseña estaba sin cifrar. Se cifra aquí y se
    // guarda después de que los usuarios lean los PIN anteriores.
    if (n != null && !n.tieneContrasena && (n.legacyContrasena ?? '').isNotEmpty) {
      n.sal = Seguridad.nuevaSal();
      n.contrasenaHuella = Seguridad.huella(n.legacyContrasena!, n.sal);
      _migrado = true;
    }
    if (n != null && (n.legacyPinDueno != null || n.legacyPinPersonal != null)) {
      _migrado = true;
    }
  }

  /// Guarda la cuenta si se migró desde la versión anterior.
  void guardarSiMigro() {
    if (_migrado) {
      _guardar();
      _migrado = false;
    }
  }

  void _guardar() {
    final n = negocio;
    if (n == null) {
      AppStorage.borrar(_kNegocio);
    } else {
      AppStorage.escribir(_kNegocio, jsonEncode(n.toJson()));
    }
  }

  /// Marca la sesión como iniciada (después de entrar en la nube).
  void abrirSesion() => _abrirSesion();

  void _abrirSesion() {
    sesionIniciada = true;
    AppStorage.escribir(_kSesion, 'si');
    notifyListeners();
  }

  bool correoRegistrado(String correo) {
    final n = negocio;
    final c = correo.trim().toLowerCase();
    return n != null && (n.correo == c || (n.correoGoogle.isNotEmpty && n.correoGoogle == c));
  }

  /// True si el correo y la contraseña coinciden con los guardados en este
  /// dispositivo por una versión anterior (sin nube). Sirve para pasar ese
  /// negocio a la nube sin pedir datos nuevos.
  bool contrasenaLocalCorrecta(String correo, String contrasena) {
    final n = negocio;
    return n != null &&
        correoRegistrado(correo) &&
        Seguridad.coincide(contrasena, n.sal, n.contrasenaHuella);
  }

  /// Guarda en este dispositivo los datos de un negocio nuevo (la cuenta
  /// ya se creó en la nube) e inicia sesión.
  void registrar({
    required String nombre,
    required String correo,
    String correoGoogle = '',
    String eslogan = '',
    String logo = '',
  }) {
    negocio = Negocio(
      nombre: nombre.trim(),
      correo: correo.trim().toLowerCase(),
      sal: Seguridad.nuevaSal(),
      correoGoogle: correoGoogle.trim().toLowerCase(),
      eslogan: eslogan.trim(),
      logo: logo,
    );
    _guardar();
    _abrirSesion();
  }

  /// Ya no se guarda la contraseña en el dispositivo (la tiene la nube).
  void olvidarContrasenaLocal() {
    final n = negocio;
    if (n == null || n.contrasenaHuella.isEmpty) {
      return;
    }
    n.contrasenaHuella = '';
    _guardar();
  }

  void cerrarSesion() {
    sesionIniciada = false;
    AppStorage.borrar(_kSesion);
    notifyListeners();
  }

  /// Vincula una cuenta de Google para poder entrar con ella.
  void vincularGoogle(String correoGoogle) {
    final n = negocio;
    if (n == null) {
      return;
    }
    n.correoGoogle = correoGoogle.trim().toLowerCase();
    _guardar();
    notifyListeners();
  }

  void actualizarNombre(String nuevo) {
    actualizarPerfil(nombre: nuevo);
  }

  /// Cambia los datos visibles del negocio. Lo que venga en null no cambia.
  void actualizarPerfil({String? nombre, String? eslogan, String? logo}) {
    final n = negocio;
    if (n == null) {
      return;
    }
    if (nombre != null && nombre.trim().isNotEmpty) {
      n.nombre = nombre.trim();
    }
    if (eslogan != null) {
      n.eslogan = eslogan.trim();
    }
    if (logo != null) {
      n.logo = logo;
    }
    _guardar();
    notifyListeners();
  }

  /// Quita la cuenta (después de borrar los datos del dispositivo).
  void olvidarCuenta() {
    negocio = null;
    sesionIniciada = false;
    AppStorage.borrar(_kNegocio);
    AppStorage.borrar(_kSesion);
    notifyListeners();
  }
}
