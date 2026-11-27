import 'package:flutter/material.dart';
import 'package:rim_coffee/app/route_args.dart';
import 'package:rim_coffee/app/route_names.dart';
import 'package:rim_coffee/app/theme.dart';
import 'package:rim_coffee/core/constants/app_assets.dart';
import 'package:rim_coffee/core/nube/acceso.dart';
import 'package:rim_coffee/core/nube/nube.dart';
import 'package:rim_coffee/core/services/google_auth.dart';
import 'package:rim_coffee/core/state/app_bootstrap.dart';
import 'package:rim_coffee/core/state/negocio_controller.dart';
import 'package:rim_coffee/core/utils/validadores.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';
import 'package:rim_coffee/features/shared/elegir_logo.dart';
import 'package:rim_coffee/features/shared/usuario_form_sheet.dart';

/// Crear un negocio nuevo en este dispositivo, en cuatro bloques:
/// 1. El negocio (nombre, frase y logo).
/// 2. Acceso a la cuenta (Google y/o correo y contraseña).
/// 3. El beneficiario (dueño) con su código.
/// 4. Cómo empezar (número de mesas y menú de ejemplo o vacío).
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key, this.google});

  /// Si la persona ya entró a su cuenta en la nube (desde el login), trae
  /// su correo y no se vuelve a pedir contraseña.
  final RegistroArgs? google;

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _eslogan = TextEditingController();
  final TextEditingController _correo = TextEditingController();
  final TextEditingController _clave = TextEditingController();
  final TextEditingController _confirmar = TextEditingController();
  final TextEditingController _beneficiario = TextEditingController();
  final TextEditingController _codigo = TextEditingController();
  final TextEditingController _codigoConfirmar = TextEditingController();

  String _correoGoogle = '';
  String _logo = '';
  int _mesas = 6;
  bool _menuEjemplo = true;
  bool _acepto = false;
  bool _terminosPendiente = false;
  bool _cargandoGoogle = false;
  bool _registrando = false;
  String? _errorGeneral;

  /// Ya entró a la cuenta en la nube (no hace falta crearla).
  bool _autenticado = false;

  bool get _conGoogle => _correoGoogle.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final g = widget.google;
    if (g != null) {
      _autenticado = true;
      _correoGoogle = g.correoGoogle;
      _correo.text = g.correo;
      _beneficiario.text = g.nombre;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _eslogan,
      _correo,
      _clave,
      _confirmar,
      _beneficiario,
      _codigo,
      _codigoConfirmar,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _usarGoogle() async {
    setState(() {
      _cargandoGoogle = true;
      _errorGeneral = null;
    });
    final r = await GoogleAuth.elegirCuenta();
    final cuenta = r.cuenta;
    String? error = r.error;
    if (error == null && cuenta != null) {
      error = await Nube.entrarConGoogle(idToken: cuenta.idToken, accessToken: cuenta.accessToken);
    }
    if (!mounted) {
      return;
    }
    if (error != null || cuenta == null) {
      setState(() {
        _cargandoGoogle = false;
        _errorGeneral = error;
      });
      return;
    }
    // Si esa cuenta ya tenía un negocio en la nube, se carga y listo.
    final acceso = await AccesoNube.despuesDeEntrar();
    if (!mounted) {
      return;
    }
    if (acceso.tipo == TipoAcceso.entro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta cuenta ya tenía un negocio: se cargaron sus datos.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (ruta) => false);
      return;
    }
    setState(() {
      _cargandoGoogle = false;
      if (acceso.tipo == TipoAcceso.error) {
        _errorGeneral = acceso.error;
        return;
      }
      _autenticado = true;
      _correoGoogle = cuenta.correo;
      _correo.text = cuenta.correo;
      if (_beneficiario.text.trim().isEmpty) {
        _beneficiario.text = cuenta.nombre;
      }
    });
  }

  Future<void> _elegirLogo() async {
    final ruta = await elegirLogoDeGaleria(context);
    if (ruta != null && mounted) {
      setState(() => _logo = ruta);
    }
  }

  Future<void> _registrar() async {
    setState(() {
      _errorGeneral = null;
      _terminosPendiente = !_acepto;
    });
    final valido = _formulario.currentState?.validate() ?? false;
    if (!valido || !_acepto) {
      setState(() => _errorGeneral ??= 'Revisa los campos marcados en rojo.');
      return;
    }
    setState(() => _registrando = true);
    if (!_autenticado) {
      final error = await Nube.registrar(_correo.text, _clave.text);
      if (!mounted) {
        return;
      }
      if (error != null) {
        setState(() {
          _registrando = false;
          _errorGeneral = error;
        });
        return;
      }
      _autenticado = true;
    }
    NegocioController.instance.registrar(
      nombre: _nombre.text,
      correo: _correo.text,
      correoGoogle: _correoGoogle,
      eslogan: _eslogan.text,
      logo: _logo,
    );
    AppBootstrap.prepararNegocioNuevo(
      beneficiario: _beneficiario.text,
      codigo: _codigo.text.trim(),
      mesas: _mesas,
      menuDeEjemplo: _menuEjemplo,
    );
    final errorNube = await AccesoNube.publicarNegocioNuevo();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorNube == null
              ? '¡${_nombre.text.trim()} está listo y guardado en la nube!'
              : '${_nombre.text.trim()} está listo. Se subirá a la nube cuando haya conexión.',
        ),
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (ruta) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: rcAppBar(title: 'Crear mi negocio', showBack: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Configura tu cafetería en cuatro pasos. Se guarda en la nube: entra con '
                      'la misma cuenta en cualquier dispositivo. Todo se puede cambiar después.',
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 18),
                    // ------------------------------------------------ 1. Negocio
                    _Paso(
                      numero: 1,
                      titulo: 'Tu negocio',
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _elegirLogo,
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: RcColores.of(context).borde),
                                    ),
                                    child: AppImage(
                                      _logo.isEmpty ? AppAssets.logo : _logo,
                                      fit: _logo.isEmpty ? BoxFit.contain : BoxFit.cover,
                                      width: 76,
                                      height: 76,
                                      radius: 38,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: RcColores.of(context).acento,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.photo_camera_outlined,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Toca el círculo para poner el logo de tu cafetería '
                                '(opcional). Aparece en el login, el menú y la pantalla de código.',
                                style: AppText.caption,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        RcTextField(
                          label: 'NOMBRE DEL NEGOCIO',
                          controller: _nombre,
                          hint: 'Ej. Rimbaud\'s Coffee',
                          textInputAction: TextInputAction.next,
                          validator: Validadores.nombreNegocio,
                          prefixIcon: const Icon(
                            Icons.storefront_outlined,
                            color: AppColors.muted,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 14),
                        RcTextField(
                          label: 'FRASE O ESLOGAN (OPCIONAL)',
                          controller: _eslogan,
                          hint: 'Ej. Arte y café',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.format_quote_outlined,
                            color: AppColors.muted,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    // ------------------------------------------------ 2. Acceso
                    _Paso(
                      numero: 2,
                      titulo: 'Acceso a la cuenta',
                      children: [
                        if (_autenticado)
                          SoftCard(
                            shadow: false,
                            color: RcColores.of(context).suave,
                            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_outlined, color: AppColors.ok),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _conGoogle ? 'Cuenta de Google' : 'Cuenta en la nube',
                                        style: AppText.title,
                                      ),
                                      Text(_correo.text, style: AppText.caption),
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          )
                        else if (GoogleAuth.disponible) ...[
                          BotonGoogle(
                            texto: 'Usar mi cuenta de Google',
                            cargando: _cargandoGoogle,
                            onPressed: _usarGoogle,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'O crea la cuenta con correo y contraseña:',
                            style: AppText.caption,
                          ),
                        ],
                        if (!_autenticado) ...[
                        const SizedBox(height: 14),
                        RcTextField(
                          label: 'CORREO DEL NEGOCIO',
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
                          hint: 'Mínimo 6, con letras y números',
                          textInputAction: TextInputAction.next,
                          validator: Validadores.contrasena,
                        ),
                        const SizedBox(height: 14),
                        RcPasswordField(
                          label: 'CONFIRMAR CONTRASEÑA',
                          controller: _confirmar,
                          hint: 'Repite tu contraseña',
                          textInputAction: TextInputAction.next,
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
                        ],
                      ],
                    ),
                    // ------------------------------------------------ 3. Beneficiario
                    _Paso(
                      numero: 3,
                      titulo: 'Tú, el beneficiario',
                      children: [
                        const Text(
                          'El beneficiario ve reportes, da de alta a los administradores y '
                          'cambia los ajustes. Entrarás con tu propio código de 4 a 6 dígitos.',
                          style: AppText.caption,
                        ),
                        const SizedBox(height: 14),
                        RcTextField(
                          label: 'TU NOMBRE',
                          controller: _beneficiario,
                          hint: 'Ej. Laura Rimbaud',
                          textInputAction: TextInputAction.next,
                          validator: Validadores.persona,
                          prefixIcon: const Icon(
                            Icons.workspace_premium_outlined,
                            color: AppColors.muted,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 14),
                        CampoCodigo(
                          label: 'TU CÓDIGO',
                          controller: _codigo,
                          hint: '4 a 6 dígitos',
                          validator: Validadores.pin,
                        ),
                        const SizedBox(height: 14),
                        CampoCodigo(
                          label: 'CONFIRMAR CÓDIGO',
                          controller: _codigoConfirmar,
                          hint: 'Repite tu código',
                          validator: (v) {
                            if ((v ?? '').trim() != _codigo.text.trim()) {
                              return 'Los códigos no coinciden';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    // ------------------------------------------------ 4. Arranque
                    _Paso(
                      numero: 4,
                      titulo: 'Cómo empezar',
                      children: [
                        Row(
                          children: [
                            Icon(Icons.table_restaurant_outlined, color: RcColores.of(context).secundario),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('Número de mesas', style: AppText.title),
                            ),
                            QtySelector(
                              value: _mesas,
                              onAdd: () => setState(() => _mesas = _mesas >= 60 ? 60 : _mesas + 1),
                              onRemove: () => setState(() => _mesas = _mesas <= 1 ? 1 : _mesas - 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('MENÚ', style: AppText.label),
                        const SizedBox(height: 8),
                        _Opcion(
                          titulo: 'Menú de ejemplo',
                          detalle: 'Bebidas calientes, frías y postres listos para editar.',
                          icono: Icons.local_cafe_outlined,
                          elegida: _menuEjemplo,
                          onTap: () => setState(() => _menuEjemplo = true),
                        ),
                        const SizedBox(height: 10),
                        _Opcion(
                          titulo: 'Empezar vacío',
                          detalle: 'Capturo mis propios productos, precios y fotos.',
                          icono: Icons.edit_note_outlined,
                          elegida: !_menuEjemplo,
                          onTap: () => setState(() => _menuEjemplo = false),
                        ),
                      ],
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() {
                        _acepto = !_acepto;
                        if (_acepto) {
                          _terminosPendiente = false;
                        }
                      }),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _acepto,
                            onChanged: (v) => setState(() {
                              _acepto = v ?? false;
                              if (_acepto) {
                                _terminosPendiente = false;
                              }
                            }),
                          ),
                          const Expanded(
                            child: Text(
                              'Acepto el aviso de privacidad: los nombres de clientes y del '
                              'personal se guardan en este dispositivo.',
                              style: AppText.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_terminosPendiente)
                      const Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 4),
                        child: Text(
                          'Debes aceptar para continuar',
                          style: TextStyle(fontSize: 12, color: AppColors.danger),
                        ),
                      ),
                    if (_errorGeneral != null) ...[
                      const SizedBox(height: 8),
                      AvisoError(_errorGeneral!),
                    ],
                    const SizedBox(height: 18),
                    RcButton(
                      label: 'Crear mi negocio',
                      icon: Icons.check_circle_outline,
                      cargando: _registrando,
                      onPressed: _registrar,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloque numerado del registro.
class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.titulo, required this.children});

  final int numero;
  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: RcColores.of(context).primario,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$numero',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(titulo, style: AppText.h3)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Opción seleccionable (tarjeta con borde caramelo cuando está elegida).
class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.elegida,
    required this.onTap,
  });

  final String titulo;
  final String detalle;
  final IconData icono;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elegida ? RcColores.of(context).suave : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: elegida ? RcColores.of(context).acento : RcColores.of(context).borde,
            width: elegida ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icono, color: elegida ? RcColores.of(context).secundario : AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: AppText.title),
                  Text(detalle, style: AppText.caption),
                ],
              ),
            ),
            Icon(
              elegida ? Icons.radio_button_checked : Icons.radio_button_off,
              color: elegida ? RcColores.of(context).acento : RcColores.of(context).borde,
            ),
          ],
        ),
      ),
    );
  }
}
