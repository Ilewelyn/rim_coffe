import 'package:flutter/material.dart';
import 'package:rim_coffee/app/route_names.dart';
import 'package:rim_coffee/core/state/sesion_cliente.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';

/// Salir del modo Cliente: quien atiende escribe su código, la tablet
/// vuelve al modo Personal con su turno y, si el cliente ya envió su
/// pedido, se abre directo la pestaña Pedidos para atenderlo.
Future<void> salirModoCliente(BuildContext context) async {
  final navegador = Navigator.of(context);
  final usuario = await pedirCodigo(
    context,
    titulo: 'Recuperar la tablet',
    mensaje: 'Escribe tu código para salir del modo Cliente y ver el pedido.',
  );
  if (usuario == null) {
    return;
  }
  final habiaPedido = SesionCliente.instance.pedidoEnviado;
  UsuariosController.instance.iniciarTurno(usuario);
  SesionCliente.instance.salir();
  navegador.pushNamedAndRemoveUntil(
    Routes.home,
    (ruta) => false,
    arguments: habiaPedido ? 1 : 0,
  );
}

/// Envuelve un widget (normalmente el logo) con un gesto discreto: al
/// mantenerlo presionado se pide un código para salir del modo Cliente.
/// El cliente no ve ningún botón que lo lleve ahí.
class SalidaDiscreta extends StatelessWidget {
  const SalidaDiscreta({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => salirModoCliente(context),
      child: child,
    );
  }
}
