import 'package:flutter/material.dart';
import 'package:rim_coffee/app/theme.dart';

/// Círculo con las iniciales de una persona. El beneficiario lleva
/// fondo caramelo y una pequeña insignia.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({
    super.key,
    required this.iniciales,
    this.beneficiario = false,
    this.tamano = 44,
    this.apagado = false,
  });

  final String iniciales;
  final bool beneficiario;
  final double tamano;
  final bool apagado;

  @override
  Widget build(BuildContext context) {
    final Color fondo;
    final Color texto;
    if (apagado) {
      fondo = AppColors.line;
      texto = AppColors.muted;
    } else if (beneficiario) {
      fondo = AppColors.caramel;
      texto = Colors.white;
    } else {
      fondo = AppColors.crema;
      texto = AppColors.cafe;
    }
    return SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: tamano,
            height: tamano,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fondo,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              iniciales,
              style: TextStyle(
                fontSize: tamano * 0.36,
                fontWeight: FontWeight.w700,
                color: texto,
              ),
            ),
          ),
          if (beneficiario && !apagado)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.espresso,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star_rounded, size: tamano * 0.26, color: AppColors.caramel),
              ),
            ),
        ],
      ),
    );
  }
}
