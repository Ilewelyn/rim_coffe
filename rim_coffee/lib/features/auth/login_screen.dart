import 'package:flutter/material.dart';
import 'package:rim_coffee/app/route_args.dart';
import 'package:rim_coffee/app/route_names.dart';
import 'package:rim_coffee/app/theme.dart';
import 'package:rim_coffee/core/constants/app_assets.dart';
import 'package:rim_coffee/core/nube/acceso.dart';
import 'package:rim_coffee/core/nube/nube.dart';
import 'package:rim_coffee/core/services/google_auth.dart';
import 'package:rim_coffee/core/state/negocio_controller.dart';
import 'package:rim_coffee/core/utils/validadores.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';

/// Inicio de sesión de la cuenta del negocio: correo y contraseña, o
/// Google. Después se pide el código de quien atiende.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final TextEditingController _correo = TextEditingController();
  final TextEditingController _clave = TextEditingController();
  String? _error;
  bool _conGoogle = false;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  bool _cargando = false;

  void _irAlInicio() {
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (ruta) => false);
  }

  /// Después de entrar a la nube: unirse al negocio, subir uno anterior o
  /// crear uno nuevo.
  Future<void> _continuar({String correoGoogle = '', String nombre = ''}) async {
    final r = await AccesoNube.despuesDeEntrar();
    if (!mounted) {
      return;
    }
    setState(() {
      _cargando = false;
      _conGoogle = false;
    });
    switch (r.tipo) {
      case TipoAcceso.entro:
        _irAlInicio();
        break;
      case TipoAcceso.sinNegocio:
        Navigator.of(context).pushNamed(
          Routes.registro,
          arguments: RegistroArgs(
            correo: Nube.correo,
            correoGoogle: correoGoogle,
            nombre: nombre,
          ),
        );
        break;
      case TipoAcceso.error:
        setState(() => _error = r.error);
        break;
    }
  }

  Future<void> _entrar() async {
    setState(() => _error = null);
    final valido = _formulario.currentState?.validate() ?? false;
    if (!valido) {
      return;
    }
    setState(() => _cargando = true);
    final correo = _correo.text.trim();
    var error = await Nube.entrar(correo, _clave.text);
    // Negocio de una versión anterior (solo en este dispositivo): se crea
    // su cuenta en la nube con el mismo correo y contraseña.
    if (error == 'Correo o contraseña incorrectos.' &&
        NegocioController.instance.contrasenaLocalCorrecta(correo, _clave.text)) {
      error = await Nube.registrar(correo, _clave.text);
    }
    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() {
        _cargando = false;
        _error = error;
      });
      return;
    }
    await _continuar();
  }

  Future<void> _entrarConGoogle() async {
    setState(() {
      _error = null;
      _conGoogle = true;
    });
    final r = await GoogleAuth.elegirCuenta();
    if (!mounted) {
      return;
    }
    final cuenta = r.cuenta;
    if (r.error != null || cuenta == null) {
      setState(() {
        _conGoogle = false;
        _error = r.error;
      });
      return;
    }
    final error = await Nube.entrarConGoogle(
      idToken: cuenta.idToken,
      accessToken: cuenta.accessToken,
    );
    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() {
        _conGoogle = false;
        _error = error;
      });
      return;
    }
    await _continuar(correoGoogle: cuenta.correo, nombre: cuenta.nombre);
  }

  @override
  Widget build(BuildContext context) {
    final negocio = NegocioController.instance;
    final existeCuenta = negocio.existeCuenta;
    final alto = MediaQuery.of(context).size.height;
    final altoPortada = (alto * 0.42).clamp(260.0, 420.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.foam,
      body: Stack(
        children: [
          SizedBox(
            height: altoPortada,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [MarcaColors.marino, MarcaColors.azulado],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const AppImage(AppAssets.logo, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                NegocioController.nombreApp,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                existeCuenta
                                    ? 'Tu negocio: ${negocio.nombre}'
                                    : 'El mostrador digital para tu negocio',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, color: MarcaColors.claro),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, altoPortada - 70, 20, 28),
                  child: Column(
                    children: [
                      SoftCard(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                        radius: 28,
                        child: Form(
                          key: _formulario,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                existeCuenta ? 'Bienvenido de nuevo' : 'Comencemos',
                                style: AppText.h2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                existeCuenta
                                    ? 'Entra con la cuenta del negocio. Después cada persona '
                                        'escribe su código para atender.'
                                    : 'Entra con tu cuenta para ver tu negocio en este dispositivo, '
                                        'o crea uno nuevo.',
                                style: AppText.caption,
                              ),
                              const SizedBox(height: 20),
                              if (GoogleAuth.disponible) ...[
                                BotonGoogle(
                                  onPressed: _cargando ? null : _entrarConGoogle,
                                  cargando: _conGoogle,
                                ),
                                const SizedBox(height: 16),
                                const Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('o con tu correo', style: AppText.caption),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              RcTextField(
                                label: 'CORREO',
                                controller: _correo,
                                hint: 'nombre@correo.com',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: Validadores.correo,
                                prefixIcon: const Icon(
                                  Icons.mail_outline,
                                  color: AppColors.muted,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 14),
                              RcPasswordField(
                                label: 'CONTRASEÑA',
                                controller: _clave,
                                hint: 'Tu contraseña',
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _entrar(),
                                validator: (v) =>
                                    Validadores.requerido(v, 'Escribe tu contraseña'),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                AvisoError(_error!),
                              ],
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed(Routes.recuperar),
                                  child: const Text('¿Olvidaste tu contraseña?'),
                                ),
                              ),
                              RcButton(
                                label: 'Iniciar sesión',
                                cargando: _cargando,
                                onPressed: _conGoogle ? null : _entrar,
                              ),
                              const SizedBox(height: 10),
                              RcButton(
                                label: 'Crear mi negocio',
                                icon: Icons.storefront_outlined,
                                style: RcButtonStyle.outline,
                                onPressed: _cargando || _conGoogle
                                    ? null
                                    : () => Navigator.of(context).pushNamed(Routes.registro),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AvisoInfo(
                        existeCuenta
                            ? 'Tus datos se guardan en la nube: entra con la misma cuenta en '
                                'cualquier tablet o celular y verás el mismo negocio.'
                            : 'Tus datos se guardan en la nube. Si ya tienes un negocio, inicia '
                                'sesión y aparecerá con su menú, mesas, usuarios y pedidos.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
