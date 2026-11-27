import 'package:flutter/material.dart';
import 'package:rim_coffee/app/theme.dart';

enum RcButtonStyle { primary, caramel, outline, soft, danger }

/// Botón de ancho completo con las variantes de la app.
class RcButton extends StatelessWidget {
  const RcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = RcButtonStyle.primary,
    this.icon,
    this.height = 54,
    this.cargando = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final RcButtonStyle style;
  final IconData? icon;
  final double height;

  /// Muestra un indicador de carga y desactiva el botón.
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final c = RcColores.of(context);
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    const texto = TextStyle(fontFamily: AppFonts.sans, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2);

    final onPressed = cargando ? null : this.onPressed;
    final Widget contenido = cargando
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: c.secundario),
          )
        : icon == null
        ? Text(label, textAlign: TextAlign.center)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: 8),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    Widget boton;
    switch (style) {
      case RcButtonStyle.outline:
        boton = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: c.secundario,
            side: BorderSide(color: c.secundario, width: 1.6),
            shape: forma,
            textStyle: texto,
          ),
          child: contenido,
        );
        break;
      case RcButtonStyle.soft:
        boton = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: c.suave,
            foregroundColor: c.secundario,
            disabledBackgroundColor: AppColors.line,
            disabledForegroundColor: AppColors.muted,
            shape: forma,
            textStyle: texto,
          ),
          child: contenido,
        );
        break;
      case RcButtonStyle.danger:
        boton = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            shape: forma,
            textStyle: texto,
          ),
          child: contenido,
        );
        break;
      case RcButtonStyle.caramel:
        boton = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: c.acento,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.line,
            disabledForegroundColor: AppColors.muted,
            shape: forma,
            textStyle: texto,
          ),
          child: contenido,
        );
        break;
      case RcButtonStyle.primary:
        boton = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: c.primario,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.line,
            disabledForegroundColor: AppColors.muted,
            shape: forma,
            textStyle: texto,
          ),
          child: contenido,
        );
        break;
    }

    return SizedBox(width: double.infinity, height: height, child: boton);
  }
}
