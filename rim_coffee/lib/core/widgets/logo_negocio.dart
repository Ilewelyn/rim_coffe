import 'package:flutter/material.dart';
import 'package:rim_coffee/core/constants/app_assets.dart';
import 'package:rim_coffee/core/state/negocio_controller.dart';
import 'package:rim_coffee/core/widgets/app_image.dart';

/// Logo del negocio dentro de un círculo blanco. Usa la foto que eligió el
/// beneficiario (Panel → Negocio) o, si no hay, el logo de Rim Coffee.
class LogoNegocio extends StatelessWidget {
  const LogoNegocio({super.key, this.tamano = 54, this.borde = 4, this.sombra = false});

  final double tamano;
  final double borde;
  final bool sombra;

  @override
  Widget build(BuildContext context) {
    final negocio = NegocioController.instance;
    return ListenableBuilder(
      listenable: negocio,
      builder: (context, _) {
        final propio = negocio.logo.isNotEmpty;
        final ruta = propio ? negocio.logo : AppAssets.logo;
        return Container(
          padding: EdgeInsets.all(borde),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: sombra
                ? const [
                    BoxShadow(color: Color(0x55000000), blurRadius: 28, offset: Offset(0, 12)),
                  ]
                : null,
          ),
          child: propio
              ? AppImage(ruta, width: tamano, height: tamano, radius: tamano / 2)
              // El logo de Rim Coffee es cuadrado: se reduce para que quepa
              // completo dentro del círculo, sin esquinas que se salgan.
              : ClipOval(
                  child: SizedBox(
                    width: tamano,
                    height: tamano,
                    child: Center(
                      child: AppImage(
                        ruta,
                        width: tamano * 0.66,
                        height: tamano * 0.66,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
