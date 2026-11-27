import 'package:flutter/material.dart';
import 'package:rim_coffee/app/route_names.dart';
import 'package:rim_coffee/core/nube/acceso.dart';
import 'package:rim_coffee/core/models/usuario.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';

/// Abre el Panel del beneficiario (reportes, usuarios, negocio y seguridad).
/// Siempre pide el código de un beneficiario, aunque el turno sea suyo, para
/// que nadie entre al panel con la tablet desbloqueada.
Future<void> abrirPanelDueno(BuildContext context) async {
  final navegador = Navigator.of(context);
  final ok = await pedirPin(
    context,
    titulo: 'Panel del beneficiario',
    mensaje: 'Escribe el código del beneficiario para ver reportes y ajustes.',
    soloDueno: true,
  );
  if (ok) {
    navegador.pushNamed(Routes.dueno);
  }
}

/// Reportes para quien tenga el permiso (o con el código de alguien que lo tenga).
Future<void> abrirReportes(BuildContext context) async {
  final navegador = Navigator.of(context);
  if (UsuariosController.instance.actualPuede(Permiso.reportes)) {
    navegador.pushNamed(Routes.reportes);
    return;
  }
  final ok = await pedirPin(
    context,
    titulo: 'Reportes de ventas',
    mensaje: 'Escribe el código de alguien con permiso para ver reportes.',
    permiso: Permiso.reportes,
  );
  if (ok) {
    navegador.pushNamed(Routes.reportes);
  }
}

/// Bloquea la tablet: vuelve a la pantalla "¿Quién atiende?" para que otra
/// persona entre con su código.
void cambiarDeUsuario(BuildContext context) {
  UsuariosController.instance.cerrarTurno();
  Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (ruta) => false);
}

/// Si quien tiene el turno puede hacer algo lo deja pasar; si no, pide el
/// código de alguien que sí pueda. Devuelve quién autorizó (o null).
Future<Usuario?> autorizar(
  BuildContext context, {
  required Permiso permiso,
  required String titulo,
}) async {
  final actual = UsuariosController.instance.actual;
  if (actual != null && actual.puede(permiso)) {
    return actual;
  }
  return pedirCodigo(
    context,
    titulo: titulo,
    mensaje: 'No tienes permiso para esto. Pide a alguien autorizado que '
        'escriba su código.',
    permiso: permiso,
  );
}

/// Cierra la sesión de la cuenta del negocio y vuelve al login. Pide el
/// código de un beneficiario y una confirmación, para que nadie salga de la
/// cuenta por error. Los datos se conservan.
Future<void> cerrarSesionNegocio(BuildContext context) async {
  final navegador = Navigator.of(context);
  final pinOk = await pedirPin(
    context,
    titulo: 'Cerrar sesión',
    mensaje: 'Escribe el código del beneficiario para salir de la cuenta del negocio.',
    soloDueno: true,
  );
  if (!pinOk || !context.mounted) {
    return;
  }
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Cerrar sesión?'),
      content: const Text(
        'Para volver a entrar necesitarás el correo y la contraseña (o la '
        'cuenta de Google) del negocio. Tus datos se conservan en la nube.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  if (confirmado != true) {
    return;
  }
  await AccesoNube.salir();
  navegador.pushNamedAndRemoveUntil(Routes.login, (ruta) => false);
}
