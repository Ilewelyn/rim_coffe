import 'dart:convert';

import 'package:rim_coffee/core/state/app_bootstrap.dart';
import 'package:rim_coffee/core/storage/app_storage.dart';

/// Respaldo: exportar e importar todos los datos de la app como texto.
/// Desinstalar la app o borrar sus datos elimina la información, por eso
/// conviene guardar un respaldo de vez en cuando.
class RespaldoService {
  RespaldoService._();

  static const int _version = 2;

  /// Todos los datos de la app en un solo texto (JSON).
  static String exportar() {
    return jsonEncode({
      'app': 'rim_coffee',
      'version': _version,
      'datos': AppStorage.exportar(),
    });
  }

  /// Reemplaza los datos de la app con un respaldo. Devuelve un mensaje de
  /// error, o null si todo salió bien.
  static String? importar(String texto) {
    Object? decodificado;
    try {
      decodificado = jsonDecode(texto.trim());
    } catch (_) {
      return 'El texto no es un respaldo válido.';
    }
    if (decodificado is! Map<String, dynamic> ||
        decodificado['app'] != 'rim_coffee' ||
        decodificado['datos'] is! Map<String, dynamic>) {
      return 'El texto no es un respaldo de Rim Coffee.';
    }
    final crudos = decodificado['datos'] as Map<String, dynamic>;
    final datos = <String, String>{};
    for (final e in crudos.entries) {
      final valor = e.value;
      if (valor is String && e.key.startsWith('rc.')) {
        datos[e.key] = valor;
      }
    }
    // Datos de este dispositivo que no se importan (sesión, turno, modo
    // Cliente, carrito y cambios pendientes de subir).
    const locales = {
      'rc.v2.sesion',
      'rc.v3.turno',
      'rc.v2.modo',
      'rc.carrito',
      'rc.nube.pendientes',
    };
    datos.removeWhere((clave, _) => locales.contains(clave));
    if (datos.isEmpty) {
      return 'El respaldo no trae datos para importar.';
    }
    // Solo se reemplazan las secciones que trae el respaldo; lo demás se
    // conserva. Los cambios se suben solos a la nube.
    datos.forEach(AppStorage.escribir);
    AppBootstrap.recargarTodo();
    return null;
  }
}
