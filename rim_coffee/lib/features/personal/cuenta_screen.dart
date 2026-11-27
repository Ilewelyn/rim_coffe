import 'package:flutter/material.dart';
import 'package:rim_coffee/app/theme.dart';
import 'package:rim_coffee/core/constants/app_assets.dart';
import 'package:rim_coffee/core/models/usuario.dart';
import 'package:rim_coffee/core/services/recordatorios.dart';
import 'package:rim_coffee/core/state/config_controller.dart';
import 'package:rim_coffee/core/state/negocio_controller.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';
import 'package:rim_coffee/features/shared/acceso_dueno.dart';
import 'package:rim_coffee/features/shared/usuario_form_sheet.dart';

/// Pestaña "Mi turno" (modo Personal): quién tiene la tablet, sus permisos,
/// cambiar su código, pasar la tablet a otra persona, reportes (si tiene
/// permiso), el Panel del beneficiario y cerrar la sesión del negocio.
class CuentaScreen extends StatelessWidget {
  const CuentaScreen({super.key});

  Future<void> _cambiarMiCodigo(BuildContext context, Usuario u) async {
    final ok = await mostrarCambioCodigo(context, u, pedirActual: true);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu código se actualizó')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final negocio = NegocioController.instance;
    final config = ConfigController.instance;
    final usuarios = UsuariosController.instance;

    return Scaffold(
      appBar: rcAppBar(title: 'Mi turno'),
      body: ListenableBuilder(
        listenable: Listenable.merge([negocio, config, usuarios]),
        builder: (context, _) {
          final yo = usuarios.actual;
          final activos = usuarios.activos;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 170,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const AppImage(AppAssets.perfilPortada, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x3324160F), Color(0xEB24160F)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AvatarUsuario(
                              iniciales: yo?.iniciales ?? '?',
                              beneficiario: yo?.esBeneficiario ?? false,
                              tamano: 62,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    yo?.nombre ?? 'Sin turno',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.h2.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${yo?.rol.nombre ?? ''} · ${negocio.nombre}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, color: AppColors.latte),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _AccionRapida(
                      icono: Icons.swap_horiz_rounded,
                      texto: 'Cambiar de usuario',
                      onTap: () => cambiarDeUsuario(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AccionRapida(
                      icono: Icons.pin_outlined,
                      texto: 'Cambiar mi código',
                      onTap: yo == null ? null : () => _cambiarMiCodigo(context, yo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (yo != null)
                SoftCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lo que puedes hacer', style: AppText.h3),
                      const SizedBox(height: 10),
                      const _Fila(
                        icono: Icons.check_circle_outline,
                        texto: 'Atender mesas y pedidos',
                        color: AppColors.ok,
                      ),
                      for (final p in Permiso.values)
                        _Fila(
                          icono: yo.puede(p) ? Icons.check_circle_outline : Icons.lock_outline,
                          texto: p.nombre,
                          apagado: !yo.puede(p),
                          color: AppColors.ok,
                        ),
                      if (!yo.esBeneficiario)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Lo bloqueado se desbloquea con el código de alguien que tenga '
                            'el permiso. El beneficiario puede cambiar tus permisos.',
                            style: AppText.caption,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SoftCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('El negocio', style: AppText.h3),
                    const SizedBox(height: 6),
                    const EstadoNubeFila(compacta: true),
                    const SizedBox(height: 6),
                    _Fila(icono: Icons.schedule, texto: config.horario),
                    _Fila(
                      icono: Icons.phone_outlined,
                      texto: config.telefono.isEmpty ? 'Sin teléfono' : config.telefono,
                    ),
                    _Fila(
                      icono: Icons.table_restaurant_outlined,
                      texto: '${config.mesas.length} mesas',
                    ),
                    const SizedBox(height: 6),
                    const Text('EQUIPO', style: AppText.label),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in activos)
                          Chip(
                            avatar: CircleAvatar(
                              backgroundColor: p.esBeneficiario ? AppColors.caramel : AppColors.latte,
                              child: Text(
                                p.iniciales,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: p.esBeneficiario ? Colors.white : AppColors.cafe,
                                ),
                              ),
                            ),
                            label: Text(p.nombre),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: StatefulBuilder(
                  builder: (context, actualizar) => SwitchListTile(
                    value: Recordatorios.activos,
                    onChanged: (v) async {
                      await Recordatorios.cambiarActivos(v);
                      actualizar(() {});
                    },
                    activeTrackColor: AppColors.cafe,
                    secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.cafe),
                    title: const Text('Recordatorios en este dispositivo', style: AppText.title),
                    subtitle: const Text(
                      'Avisa si una mesa lleva 2 horas abierta o si un pedido lleva '
                      '15 minutos sin iniciar.',
                      style: AppText.caption,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (yo != null && yo.puede(Permiso.reportes) && !yo.esBeneficiario) ...[
                RcButton(
                  label: 'Reportes de ventas',
                  icon: Icons.bar_chart_rounded,
                  style: RcButtonStyle.caramel,
                  onPressed: () => abrirReportes(context),
                ),
                const SizedBox(height: 10),
              ],
              RcButton(
                label: (yo?.esBeneficiario ?? false)
                    ? 'Panel del beneficiario'
                    : 'Panel del beneficiario (código)',
                icon: Icons.workspace_premium_outlined,
                onPressed: () => abrirPanelDueno(context),
              ),
              const SizedBox(height: 10),
              RcButton(
                label: 'Cerrar sesión del negocio',
                icon: Icons.logout,
                style: RcButtonStyle.outline,
                onPressed: () => cerrarSesionNegocio(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccionRapida extends StatelessWidget {
  const _AccionRapida({required this.icono, required this.texto, required this.onTap});

  final IconData icono;
  final String texto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          Icon(icono, color: AppColors.caramel, size: 26),
          const SizedBox(height: 6),
          Text(texto, textAlign: TextAlign.center, style: AppText.title),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.texto,
    this.apagado = false,
    this.color = AppColors.cafe,
  });

  final IconData icono;
  final String texto;
  final bool apagado;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, size: 18, color: apagado ? AppColors.latte : color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: AppText.body.copyWith(color: apagado ? AppColors.muted : AppColors.espresso),
            ),
          ),
        ],
      ),
    );
  }
}
