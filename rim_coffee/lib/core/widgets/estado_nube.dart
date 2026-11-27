import 'package:flutter/material.dart';
import 'package:rim_coffee/app/theme.dart';
import 'package:rim_coffee/core/nube/sincronizacion.dart';
import 'package:rim_coffee/core/utils/formato.dart';

/// Fila con el estado de la nube: al día, sincronizando, pendiente o sin
/// conexión, y un botón para sincronizar ahora.
class EstadoNubeFila extends StatelessWidget {
  const EstadoNubeFila({super.key, this.compacta = false});

  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final sync = Sincronizacion.instance;
    return ValueListenableBuilder<EstadoNube>(
      valueListenable: sync.estado,
      builder: (context, estado, _) {
        final ultima = sync.ultimaVez.value;
        final (IconData icono, Color color, String texto) = switch (estado) {
          EstadoNube.alDia => (
              Icons.cloud_done_outlined,
              AppColors.ok,
              ultima == null ? 'Nube: al día' : 'Nube: al día · ${horaDe(ultima)}',
            ),
          EstadoNube.sincronizando => (Icons.cloud_sync_outlined, AppColors.caramel, 'Nube: sincronizando…'),
          EstadoNube.pendiente => (Icons.cloud_upload_outlined, AppColors.caramel, 'Nube: cambios por subir'),
          EstadoNube.sinConexion => (
              Icons.cloud_off_outlined,
              AppColors.danger,
              'Sin conexión: se guarda en el dispositivo',
            ),
          EstadoNube.apagada => (Icons.cloud_off_outlined, AppColors.muted, 'Nube: sin sesión'),
        };
        return Row(
          children: [
            Icon(icono, color: color, size: compacta ? 18 : 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                style: compacta ? AppText.caption.copyWith(color: color) : AppText.title,
              ),
            ),
            if (estado != EstadoNube.apagada && estado != EstadoNube.sincronizando)
              TextButton(
                onPressed: sync.sincronizarAhora,
                child: Text(compacta ? 'Actualizar' : 'Sincronizar'),
              ),
          ],
        );
      },
    );
  }
}
