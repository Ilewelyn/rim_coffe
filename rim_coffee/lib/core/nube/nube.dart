import 'package:flutter/foundation.dart';
import 'package:rim_coffee/core/nube/nube_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de una operación con la nube: null = bien, texto = error.
typedef ErrorNube = String?;

/// Conexión con Supabase: cuentas (correo/contraseña o Google) y la
/// función del servidor para recuperar la contraseña.
///
/// La cuenta de Supabase es la "cuenta del negocio": todos los
/// dispositivos que entran con ella comparten los mismos datos.
class Nube {
  Nube._();

  static bool _lista = false;

  static Future<void> init() async {
    try {
      await Supabase.initialize(url: NubeConfig.url, anonKey: NubeConfig.llaveAnon);
      _lista = true;
    } catch (e) {
      debugPrint('No se pudo iniciar Supabase: $e');
    }
  }

  static bool get disponible => _lista;

  static SupabaseClient get cliente => Supabase.instance.client;

  static bool get haySesion => _lista && cliente.auth.currentSession != null;

  /// Identificador del negocio en la nube (el usuario de Supabase).
  static String? get uid => _lista ? cliente.auth.currentUser?.id : null;

  static String get correo => (_lista ? cliente.auth.currentUser?.email : null) ?? '';

  static bool get googleActivo => NubeConfig.googleWebClientId.isNotEmpty;

  /// True si la cuenta tiene contraseña (no solo Google).
  static bool get tieneContrasena {
    if (!_lista) {
      return true;
    }
    final identidades = cliente.auth.currentUser?.identities;
    if (identidades == null || identidades.isEmpty) {
      return true;
    }
    return identidades.any((i) => i.provider == 'email');
  }

  /// Traduce los errores de Supabase a mensajes claros.
  static String mensaje(Object e) {
    final texto = e is AuthException ? e.message : e.toString();
    final t = texto.toLowerCase();
    if (t.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (t.contains('already registered') || t.contains('already been registered')) {
      return 'Ya existe una cuenta con ese correo. Inicia sesión.';
    }
    if (t.contains('email not confirmed')) {
      return 'Falta confirmar el correo. Revisa tu bandeja de entrada (o desactiva '
          '"Confirm email" en Supabase).';
    }
    if (t.contains('password') && t.contains('characters')) {
      return 'La contraseña es demasiado corta.';
    }
    if (t.contains('rate limit') || t.contains('too many')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }
    if (t.contains('socket') ||
        t.contains('failed host lookup') ||
        t.contains('network') ||
        t.contains('connection') ||
        t.contains('clientexception') ||
        e is AuthRetryableFetchException) {
      final detalle = texto.length > 140 ? texto.substring(0, 140) : texto;
      return 'No se pudo conectar con el servidor de la nube. Revisa tu internet '
          '(si usas VPN o "DNS privado", desactívalo y prueba). Detalle: $detalle';
    }
    if (t.contains('provider is not enabled') || t.contains('unsupported provider')) {
      return 'Google todavía no está activado en Supabase (Authentication → Providers → Google).';
    }
    return 'No se pudo completar: $texto';
  }

  static ErrorNube _sinNube() => _lista ? null : 'No se pudo conectar con la nube.';

  /// Crea la cuenta del negocio en la nube.
  static Future<ErrorNube> registrar(String correo, String contrasena) async {
    final sin = _sinNube();
    if (sin != null) {
      return sin;
    }
    try {
      final r = await cliente.auth.signUp(email: correo.trim().toLowerCase(), password: contrasena);
      if (r.session == null) {
        return 'Cuenta creada, pero falta confirmar el correo. Revisa tu bandeja de entrada '
            'y después inicia sesión.';
      }
      return null;
    } catch (e) {
      return mensaje(e);
    }
  }

  static Future<ErrorNube> entrar(String correo, String contrasena) async {
    final sin = _sinNube();
    if (sin != null) {
      return sin;
    }
    try {
      await cliente.auth.signInWithPassword(
        email: correo.trim().toLowerCase(),
        password: contrasena,
      );
      return null;
    } catch (e) {
      return mensaje(e);
    }
  }

  static Future<ErrorNube> entrarConGoogle({
    required String idToken,
    required String accessToken,
  }) async {
    final sin = _sinNube();
    if (sin != null) {
      return sin;
    }
    try {
      await cliente.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return null;
    } catch (e) {
      return mensaje(e);
    }
  }

  static Future<void> salir() async {
    if (!_lista) {
      return;
    }
    try {
      await cliente.auth.signOut();
    } catch (_) {
      // Sin internet: la sesión local se borra de todos modos.
    }
  }

  /// Cambia la contraseña comprobando antes la actual.
  static Future<ErrorNube> cambiarContrasena({
    required String actual,
    required String nueva,
  }) async {
    final sin = _sinNube();
    if (sin != null) {
      return sin;
    }
    try {
      if (actual.isNotEmpty) {
        await cliente.auth.signInWithPassword(email: correo, password: actual);
      }
      await cliente.auth.updateUser(UserAttributes(password: nueva));
      return null;
    } catch (e) {
      final m = mensaje(e);
      return m == 'Correo o contraseña incorrectos.' ? 'La contraseña actual no es correcta.' : m;
    }
  }

  /// Olvidé mi contraseña: el servidor comprueba el código del beneficiario
  /// y pone la contraseña nueva.
  static Future<ErrorNube> recuperarContrasena({
    required String correo,
    required String codigo,
    required String nueva,
  }) async {
    final sin = _sinNube();
    if (sin != null) {
      return sin;
    }
    try {
      final r = await cliente.functions.invoke(
        'recuperar-contrasena',
        body: {'correo': correo.trim().toLowerCase(), 'codigo': codigo.trim(), 'nueva': nueva},
      );
      if (r.status == 200) {
        return null;
      }
      return _errorFuncion(r.data);
    } on FunctionException catch (e) {
      return _errorFuncion(e.details);
    } catch (e) {
      return mensaje(e);
    }
  }

  static String _errorFuncion(Object? datos) {
    if (datos is Map && datos['error'] is String) {
      return datos['error'] as String;
    }
    return 'No se pudo cambiar la contraseña. Inténtalo de nuevo.';
  }
}
