import 'package:flutter/material.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';
import 'package:rim_coffee/features/dueno/dueno_inicio_screen.dart';
import 'package:rim_coffee/features/dueno/negocio_screen.dart';
import 'package:rim_coffee/features/dueno/usuarios_admin_screen.dart';
import 'package:rim_coffee/features/dueno/reportes_screen.dart';
import 'package:rim_coffee/features/dueno/seguridad_screen.dart';

/// PANEL DEL BENEFICIARIO: Inicio con indicadores · Reportes · Usuarios
/// (altas, bajas, permisos y códigos) · Negocio · Seguridad.
/// El botón "Salir" regresa al modo Personal.
class DuenoShell extends StatefulWidget {
  const DuenoShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<DuenoShell> createState() => _DuenoShellState();
}

class _DuenoShellState extends State<DuenoShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DuenoInicioScreen(onIrTab: (i) => setState(() => _index = i)),
          const ReportesScreen(),
          const UsuariosAdminScreen(),
          const NegocioScreen(),
          const SeguridadScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomItem('Inicio', Icons.dashboard_outlined),
          BottomItem('Reportes', Icons.bar_chart_outlined),
          BottomItem('Usuarios', Icons.groups_outlined),
          BottomItem('Negocio', Icons.storefront_outlined),
          BottomItem('Seguridad', Icons.lock_outline),
        ],
      ),
    );
  }
}
