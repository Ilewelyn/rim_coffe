import 'package:flutter/material.dart';
import 'package:rim_coffee/app/theme.dart';

/// Recuadro rojo suave con un mensaje de error.
class AvisoError extends StatelessWidget {
  const AvisoError(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE9E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2C9C0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(fontSize: 13, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recuadro informativo color crema con ícono.
class AvisoInfo extends StatelessWidget {
  const AvisoInfo(this.mensaje, {super.key, this.icono = Icons.info_outline});

  final String mensaje;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final c = RcColores.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.suave,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: c.secundario),
          const SizedBox(width: 10),
          Expanded(child: Text(mensaje, style: AppText.caption)),
        ],
      ),
    );
  }
}
