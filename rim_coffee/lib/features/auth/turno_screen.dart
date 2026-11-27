import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rim_coffee/app/route_names.dart';
import 'package:rim_coffee/app/theme.dart';
import 'package:rim_coffee/core/models/usuario.dart';
import 'package:rim_coffee/core/state/negocio_controller.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';
import 'package:rim_coffee/core/utils/formato.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';
import 'package:rim_coffee/features/shared/acceso_dueno.dart';
import 'package:rim_coffee/features/shared/usuario_form_sheet.dart';

/// "¿Quién atiende?": la tablet está bloqueada hasta que alguien escribe su
/// código. Con el código la app sabe quién es (beneficiario o
/// administrador) y qué puede hacer.
class TurnoScreen extends StatefulWidget {
  const TurnoScreen({super.key});

  @override
  State<TurnoScreen> createState() => _TurnoScreenState();
}

class _TurnoScreenState extends State<TurnoScreen> {
  Timer? _reloj;
  DateTime _ahora = DateTime.now();

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        setState(() => _ahora = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  String? _validar(String codigo) {
    final usuarios = UsuariosController.instance;
    final v = usuarios.verificar(codigo);
    if (v.resultado == ResultadoPin.correcto && v.usuario != null) {
      _entrar(v.usuario!);
      return null;
    }
    if (v.resultado == ResultadoPin.incorrecto) {
      return 'Código incorrecto · intentos restantes: ${usuarios.intentosRestantes}';
    }
    return null;
  }

  void _entrar(Usuario usuario) {
    UsuariosController.instance.iniciarTurno(usuario);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (ruta) => false);
    messenger.showSnackBar(
      SnackBar(content: Text('${saludo()}, ${usuario.nombre} · ${usuario.rol.nombre}')),
    );
  }

  Future<void> _crearBeneficiario() async {
    final ok = await mostrarFormularioUsuario(
      context,
      rolInicial: Rol.beneficiario,
      soloBeneficiario: true,
    );
    if (ok && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final negocio = NegocioController.instance;
    final usuarios = UsuariosController.instance;
    final sinBeneficiario = !usuarios.hayBeneficiario;
    final tamano = MediaQuery.of(context).size;
    final horizontal = tamano.width >= 760 && tamano.width > tamano.height;
    final tecla = tamano.height < 700 ? 60.0 : 70.0;

    final marca = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LogoNegocio(tamano: 84, borde: 5, sombra: true),
        const SizedBox(height: 18),
        Text(
          negocio.nombre,
          textAlign: TextAlign.center,
          style: AppText.display.copyWith(color: Colors.white, fontSize: 34),
        ),
        const SizedBox(height: 6),
        Text(
          negocio.eslogan,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.latte),
        ),
        const SizedBox(height: 22),
        Text(
          horaDe(_ahora),
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        Text(
          fechaLarga(_ahora),
          style: const TextStyle(fontSize: 13, color: AppColors.latte),
        ),
      ],
    );

    final panel = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '¿Quién atiende?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Escribe tu código personal',
          style: TextStyle(fontSize: 13, color: AppColors.latte),
        ),
        const SizedBox(height: 20),
        if (sinBeneficiario)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const Text(
                  'Este negocio todavía no tiene beneficiario con código. '
                  'Créalo para poder entrar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 14),
                RcButton(
                  label: 'Crear beneficiario',
                  icon: Icons.workspace_premium_outlined,
                  style: RcButtonStyle.caramel,
                  onPressed: _crearBeneficiario,
                ),
              ],
            ),
          )
        else
          TecladoCodigo(oscuro: true, tamanoTecla: tecla, onEnviar: _validar),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: () => cerrarSesionNegocio(context),
          icon: const Icon(Icons.logout, size: 18, color: AppColors.latte),
          label: const Text(
            'Cerrar sesión del negocio',
            style: TextStyle(color: AppColors.latte, fontWeight: FontWeight.w600),
          ),
        ),
        const Text(
          '¿Olvidaste tu código? El beneficiario puede restablecerlo en Panel → Usuarios.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: Colors.white54),
        ),
      ],
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.espresso,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A2519), AppColors.espresso],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: horizontal
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: marca),
                            const SizedBox(width: 40),
                            Expanded(child: panel),
                          ],
                        )
                      : Column(
                          children: [
                            marca,
                            const SizedBox(height: 28),
                            panel,
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
