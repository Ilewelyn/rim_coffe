import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rim_coffee/core/nube/nube_config.dart';

/// Cuenta de Google elegida por el usuario.
class CuentaGoogle {
  const CuentaGoogle({
    required this.correo,
    required this.nombre,
    required this.idToken,
    required this.accessToken,
  });

  final String correo;
  final String nombre;

  /// Credenciales para entrar a la nube (Supabase) con esta cuenta.
  final String idToken;
  final String accessToken;
}

/// Resultado de "Continuar con Google": la cuenta elegida, un mensaje de
/// error, o ninguno de los dos si el usuario canceló.
class ResultadoGoogle {
  const ResultadoGoogle({this.cuenta, this.error});

  final CuentaGoogle? cuenta;
  final String? error;
}

/// Inicio de sesión con Google (solo se usa para saber qué correo es el
/// del usuario; los datos siguen guardados en el dispositivo).
///
/// Para que funcione hay que registrar la app en Google Cloud con su
/// nombre de paquete y su huella SHA-1 (ver GOOGLE_LOGIN.md). Si no está
/// configurado, se muestra un mensaje claro y se puede seguir usando
/// correo y contraseña.
class GoogleAuth {
  GoogleAuth._();

  /// Solo en Android y cuando ya está el ID de cliente web de Google
  /// (ver NubeConfig y GOOGLE_LOGIN.md).
  static bool get disponible => !kIsWeb && NubeConfig.googleWebClientId.isNotEmpty;

  static final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email'],
    serverClientId:
        NubeConfig.googleWebClientId.isEmpty ? null : NubeConfig.googleWebClientId,
  );

  static Future<ResultadoGoogle> elegirCuenta() async {
    if (!disponible) {
      return const ResultadoGoogle(
        error: 'El inicio con Google todavía no está activado en esta versión.',
      );
    }
    try {
      // Cierra la sesión anterior para que siempre pregunte qué cuenta usar.
      await _google.signOut();
    } catch (_) {
      // No había sesión: no importa.
    }
    try {
      final cuenta = await _google.signIn();
      if (cuenta == null) {
        return const ResultadoGoogle();
      }
      final credenciales = await cuenta.authentication;
      final idToken = credenciales.idToken;
      final accessToken = credenciales.accessToken;
      if (idToken == null || accessToken == null) {
        return const ResultadoGoogle(
          error: 'Google no entregó las credenciales. Revisa el ID de cliente web (GOOGLE_LOGIN.md).',
        );
      }
      return ResultadoGoogle(
        cuenta: CuentaGoogle(
          correo: cuenta.email.trim().toLowerCase(),
          nombre: cuenta.displayName ?? '',
          idToken: idToken,
          accessToken: accessToken,
        ),
      );
    } on PlatformException catch (e) {
      if (_esCancelacion(e.code, e.message ?? '')) {
        return const ResultadoGoogle();
      }
      return ResultadoGoogle(error: _mensaje('${e.code} ${e.message ?? ''}'));
    } catch (e) {
      return ResultadoGoogle(error: _mensaje(e.toString()));
    }
  }

  /// Código de estado de Google dentro del texto del error
  /// (por ejemplo "ApiException: 10: " o solo "10: ").
  static int? _codigo(String detalle) {
    final m = RegExp(r'(?:^|[^\d])(\d{1,5})\s*:').firstMatch(detalle);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  static bool _esCancelacion(String codigo, String mensaje) {
    return codigo == 'sign_in_canceled' || _codigo(mensaje) == 12501;
  }

  static String _mensaje(String detalle) {
    final codigo = _codigo(detalle);
    final sinConfigurar = codigo == 10 ||
        codigo == 12500 ||
        detalle.contains('DEVELOPER_ERROR') ||
        (detalle.contains('sign_in_failed') && codigo == null);
    if (sinConfigurar) {
      return 'El inicio con Google todavía no está configurado para esta app '
          '(código ${codigo ?? '?'}). Mientras tanto usa tu correo y contraseña; '
          'para activarlo sigue la guía GOOGLE_LOGIN.md.';
    }
    if (codigo == 7 || detalle.contains('network_error')) {
      return 'Google no pudo conectarse (código 7). Revisa el internet, que la hora del '
          'teléfono sea automática y que Google Play Services esté actualizado.';
    }
    return 'No se pudo iniciar con Google (código ${codigo ?? detalle.split(' ').first}). '
        'Inténtalo de nuevo o usa tu correo.';
  }
}
