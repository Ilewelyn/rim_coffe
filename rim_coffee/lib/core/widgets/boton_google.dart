import 'package:flutter/material.dart';
import 'package:rim_coffee/app/theme.dart';

/// Botón blanco "Continuar con Google".
class BotonGoogle extends StatelessWidget {
  const BotonGoogle({super.key, required this.onPressed, this.cargando = false, this.texto});

  final VoidCallback? onPressed;
  final bool cargando;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: cargando ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.espresso,
          side: const BorderSide(color: AppColors.line, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cargando)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Text(
                'G',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4285F4),
                ),
              ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                texto ?? 'Continuar con Google',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
