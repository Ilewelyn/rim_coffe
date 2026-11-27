import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rim_coffee/app/route_names.dart';
import 'package:rim_coffee/app/theme.dart';
import 'package:rim_coffee/core/constants/app_assets.dart';
import 'package:rim_coffee/core/state/negocio_controller.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';

/// Pantalla de inicio: animación del logo y paso automático al login
/// (o directo al modo Personal si ya hay una sesión guardada).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _escala;
  late final Animation<double> _opacidad;
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    _escala = CurvedAnimation(parent: _controlador, curve: Curves.easeOutBack);
    _opacidad = CurvedAnimation(parent: _controlador, curve: Curves.easeIn);
    _temporizador = Timer(const Duration(milliseconds: 2800), _continuar);
  }

  void _continuar() {
    if (!mounted) {
      return;
    }
    final destino = NegocioController.instance.estaAutenticado
        ? Routes.home
        : Routes.login;
    Navigator.of(context).pushReplacementNamed(destino);
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final negocio = NegocioController.instance;
    return Scaffold(
      backgroundColor: MarcaColors.marino,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [MarcaColors.marino, MarcaColors.azulado],
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _opacidad,
                  child: ScaleTransition(
                    scale: _escala,
                    child: Container(
                      width: 150,
                      height: 150,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(38),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55000000),
                            blurRadius: 30,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const AppImage(AppAssets.logo, fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _opacidad,
                  child: const Text(
                    NegocioController.nombreApp,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: _opacidad,
                  child: const Text(
                    'El mostrador digital para tu negocio',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: MarcaColors.claro),
                  ),
                ),
                if (negocio.existeCuenta) ...[
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _opacidad,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        negocio.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(flex: 3),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: MarcaColors.naranja,
                  ),
                ),
                const SizedBox(height: 42),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
