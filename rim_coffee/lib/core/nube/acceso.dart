import 'package:rim_coffee/core/nube/nube.dart';
import 'package:rim_coffee/core/nube/sincronizacion.dart';
import 'package:rim_coffee/core/state/app_bootstrap.dart';
import 'package:rim_coffee/core/state/negocio_controller.dart';
import 'package:rim_coffee/core/state/sesion_cliente.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';

/// Qué pasó después de entrar a la cuenta en la nube.
enum TipoAcceso { entro, sinNegocio, error }

class ResultadoAcceso {
  const ResultadoAcceso(this.tipo, [this.error]);

  final TipoAcceso tipo;
  final String? error;
}

/// Lo que se hace al iniciar sesión en la nube desde cualquier dispositivo.
class AccesoNube {
  AccesoNube._();

  /// - Si la cuenta ya tiene un negocio en la nube, este dispositivo baja
  ///   todos sus datos (menú, mesas, usuarios, pedidos…) y se une.
  /// - Si no, pero en este dispositivo hay un negocio con ese correo (de una
  ///   versión anterior sin nube), se sube a la nube.
  /// - Si no hay nada, hay que crear el negocio ([TipoAcceso.sinNegocio]).
  static Future<ResultadoAcceso> despuesDeEntrar() async {
    final sync = Sincronizacion.instance;
    final negocio = NegocioController.instance;
    try {
      if (await sync.hayNegocioEnNube()) {
        await sync.detener();
        SesionCliente.instance.salir();
        UsuariosController.instance.cerrarTurno();
        await sync.descargarTodo();
        AppBootstrap.recargarTodo();
        negocio.abrirSesion();
        await sync.iniciar();
        return const ResultadoAcceso(TipoAcceso.entro);
      }
      if (negocio.existeCuenta && negocio.correoRegistrado(Nube.correo)) {
        negocio.olvidarContrasenaLocal();
        await sync.detener();
        await sync.subirTodo();
        negocio.abrirSesion();
        await sync.iniciar();
        return const ResultadoAcceso(TipoAcceso.entro);
      }
      return const ResultadoAcceso(TipoAcceso.sinNegocio);
    } catch (e) {
      return ResultadoAcceso(TipoAcceso.error, Nube.mensaje(e));
    }
  }

  /// Negocio recién creado en este dispositivo: se sube completo a la nube.
  static Future<String?> publicarNegocioNuevo() async {
    final sync = Sincronizacion.instance;
    await sync.detener();
    try {
      await sync.subirTodo();
      await sync.iniciar();
      return null;
    } catch (e) {
      // Sin conexión: se queda todo pendiente y se sube después.
      sync.marcarTodoPendiente();
      await sync.iniciar();
      return Nube.mensaje(e);
    }
  }

  /// Cierra la sesión en este dispositivo (los datos siguen en la nube).
  static Future<void> salir() async {
    await Sincronizacion.instance.detener();
    await Nube.salir();
    SesionCliente.instance.salir();
    UsuariosController.instance.cerrarTurno();
    NegocioController.instance.cerrarSesion();
  }
}
