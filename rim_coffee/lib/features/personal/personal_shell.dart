import 'package:flutter/material.dart';
import 'package:rim_coffee/core/models/usuario.dart';
import 'package:rim_coffee/core/state/pedidos_controller.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';
import 'package:rim_coffee/features/personal/cuenta_screen.dart';
import 'package:rim_coffee/features/personal/mesas_screen.dart';
import 'package:rim_coffee/features/personal/pedidos_screen.dart';
import 'package:rim_coffee/features/shared/productos_screen.dart';

/// MODO PERSONAL (quien atiende con su código): Mesas · Pedidos ·
/// Productos · Mi turno. Sin el permiso "Editar menú" la pestaña Productos
/// solo permite marcar productos como agotados.
class PersonalShell extends StatefulWidget {
  const PersonalShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<PersonalShell> createState() => _PersonalShellState();
}

class _PersonalShellState extends State<PersonalShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final pedidos = PedidosController.instance;
    final usuarios = UsuariosController.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([pedidos, usuarios]),
      builder: (context, _) {
        final editaMenu = usuarios.actualPuede(Permiso.menu);
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              MesasScreen(onVerPedidos: () => setState(() => _index = 1)),
              const PedidosScreen(),
              ProductosScreen(
                key: ValueKey('productos-$editaMenu'),
                soloDisponibilidad: !editaMenu,
              ),
              const CuentaScreen(),
            ],
          ),
          bottomNavigationBar: AppBottomBar(
            index: _index,
            onTap: (i) => setState(() => _index = i),
            items: [
              const BottomItem('Mesas', Icons.table_restaurant_outlined),
              BottomItem(
                'Pedidos',
                Icons.receipt_long_outlined,
                badge: pedidos.totalPendientes,
              ),
              BottomItem(
                editaMenu ? 'Menú' : 'Agotados',
                Icons.local_cafe_outlined,
              ),
              const BottomItem('Mi turno', Icons.badge_outlined),
            ],
          ),
        );
      },
    );
  }
}
