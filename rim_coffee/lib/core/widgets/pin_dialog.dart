import 'package:flutter/material.dart';
import 'package:rim_coffee/app/theme.dart';
import 'package:rim_coffee/core/models/usuario.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';
import 'package:rim_coffee/core/widgets/teclado_codigo.dart';

/// Pide el código de una persona en una ventana y devuelve de quién es
/// (o null si se canceló).
///
/// - Con [soloBeneficiario] solo vale el código de un beneficiario.
/// - Con [permiso] la persona debe tener ese permiso.
/// - Tras 3 códigos incorrectos el teclado se bloquea 30 segundos.
Future<Usuario?> pedirCodigo(
  BuildContext context, {
  required String titulo,
  String mensaje = '',
  bool soloBeneficiario = false,
  Permiso? permiso,
}) {
  return showDialog<Usuario>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CodigoDialog(
      titulo: titulo,
      mensaje: mensaje,
      soloBeneficiario: soloBeneficiario,
      permiso: permiso,
    ),
  );
}

/// Igual que [pedirCodigo] pero solo dice si el código fue aceptado.
/// Con [soloDueno] solo vale el código de un beneficiario.
Future<bool> pedirPin(
  BuildContext context, {
  required String titulo,
  String mensaje = '',
  bool soloDueno = false,
  Permiso? permiso,
}) async {
  final usuario = await pedirCodigo(
    context,
    titulo: titulo,
    mensaje: mensaje,
    soloBeneficiario: soloDueno,
    permiso: permiso,
  );
  return usuario != null;
}

class _CodigoDialog extends StatelessWidget {
  const _CodigoDialog({
    required this.titulo,
    required this.mensaje,
    required this.soloBeneficiario,
    required this.permiso,
  });

  final String titulo;
  final String mensaje;
  final bool soloBeneficiario;
  final Permiso? permiso;

  String? _validar(BuildContext context, String codigo) {
    final usuarios = UsuariosController.instance;
    final v = usuarios.verificar(
      codigo,
      soloBeneficiario: soloBeneficiario,
      permiso: permiso,
    );
    if (v.resultado == ResultadoPin.correcto) {
      Navigator.of(context).pop(v.usuario);
      return null;
    }
    if (v.resultado == ResultadoPin.incorrecto) {
      return 'Código incorrecto · intentos restantes: ${usuarios.intentosRestantes}';
    }
    if (v.resultado == ResultadoPin.sinPermiso) {
      final nombre = v.usuario?.nombre ?? 'Esa persona';
      final p = permiso;
      if (soloBeneficiario || p == null) {
        return 'Solo el beneficiario puede hacer esto.';
      }
      return '$nombre no tiene permiso para: ${p.nombre.toLowerCase()}.';
    }
    // Bloqueado: el teclado muestra la cuenta regresiva.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final tecla = ancho < 360 ? 58.0 : 64.0;

    return Dialog(
      backgroundColor: AppColors.foam,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.crema,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  soloBeneficiario ? Icons.workspace_premium_outlined : Icons.lock_outline,
                  color: AppColors.cafe,
                ),
              ),
              const SizedBox(height: 12),
              Text(titulo, textAlign: TextAlign.center, style: AppText.h3),
              if (mensaje.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(mensaje, textAlign: TextAlign.center, style: AppText.caption),
              ],
              const SizedBox(height: 18),
              TecladoCodigo(
                tamanoTecla: tecla,
                onEnviar: (codigo) => _validar(context, codigo),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
