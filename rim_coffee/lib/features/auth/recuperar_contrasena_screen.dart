import 'package:flutter/material.dart';
import 'package:rim_coffee/app/theme.dart';
import 'package:rim_coffee/core/constants/app_assets.dart';
import 'package:rim_coffee/core/nube/nube.dart';
import 'package:rim_coffee/core/utils/validadores.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';
import 'package:rim_coffee/features/shared/usuario_form_sheet.dart';

/// Olvidé mi contraseña: se escribe el correo del negocio, el código de un
/// beneficiario y la contraseña nueva. El servidor (Supabase) comprueba el
/// código y cambia la contraseña. Sirve desde cualquier dispositivo.
class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  State<RecuperarContrasenaScreen> createState() => _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final TextEditingController _correo = TextEditingController();
  final TextEditingController _codigo = TextEditingController();
  final TextEditingController _clave = TextEditingController();
  final TextEditingController _confirmar = TextEditingController();
  bool _cargando = false;
  bool _listo = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _codigo.dispose();
    _clave.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _error = null);
    if (!(_formulario.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _cargando = true);
    final error = await Nube.recuperarContrasena(
      correo: _correo.text,
      codigo: _codigo.text,
      nueva: _clave.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _cargando = false;
      _error = error;
      _listo = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: rcAppBar(title: 'Recuperar contraseña', showBack: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: _listo ? _pasoListo() : _formularioRecuperar(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _encabezado(String titulo, String texto) {
    return Column(
      children: [
        const Center(
          child: AppImage(AppAssets.recuperar, width: 130, height: 130, radius: 65),
        ),
        const SizedBox(height: 16),
        Text(titulo, textAlign: TextAlign.center, style: AppText.h2),
        const SizedBox(height: 6),
        Text(texto, textAlign: TextAlign.center, style: AppText.caption),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _formularioRecuperar() {
    return Form(
      key: _formulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _encabezado(
            '¿Olvidaste tu contraseña?',
            'Escribe el correo del negocio y tu código de beneficiario (el que usas para '
                'entrar a atender). Después elige una contraseña nueva.',
          ),
          RcTextField(
            label: 'CORREO DEL NEGOCIO',
            controller: _correo,
            hint: 'nombre@correo.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validadores.correo,
            prefixIcon: const Icon(Icons.mail_outline, color: AppColors.muted, size: 20),
          ),
          const SizedBox(height: 14),
          CampoCodigo(
            label: 'CÓDIGO DEL BENEFICIARIO',
            controller: _codigo,
            hint: '4 a 6 dígitos',
            validator: Validadores.pin,
          ),
          const SizedBox(height: 14),
          RcPasswordField(
            label: 'NUEVA CONTRASEÑA',
            controller: _clave,
            hint: 'Mínimo 6, con letras y números',
            validator: Validadores.contrasena,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          RcPasswordField(
            label: 'CONFIRMAR CONTRASEÑA',
            controller: _confirmar,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Confirma tu contraseña';
              }
              if (v != _clave.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            AvisoError(_error!),
          ],
          const SizedBox(height: 20),
          RcButton(label: 'Cambiar contraseña', cargando: _cargando, onPressed: _guardar),
          const SizedBox(height: 12),
          const AvisoInfo(
            'Si tu cuenta es de Google, no necesitas contraseña: usa "Continuar con Google". '
            'Por seguridad solo se permiten 5 intentos por hora.',
          ),
        ],
      ),
    );
  }

  Widget _pasoListo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _encabezado(
          '¡Contraseña actualizada!',
          'Ya puedes iniciar sesión con tu nueva contraseña en cualquier dispositivo.',
        ),
        RcButton(
          label: 'Volver al acceso',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
