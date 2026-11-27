import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rim_coffee/app/theme.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';

/// Recibe el código escrito. Devuelve un mensaje de error, o null si se aceptó.
typedef ValidarCodigo = String? Function(String codigo);

/// Teclado numérico para escribir un código de 4 a 6 dígitos, con puntos
/// que se llenan, mensaje de error y cuenta regresiva cuando se bloquea
/// por demasiados intentos. Funciona sobre fondo claro u oscuro.
class TecladoCodigo extends StatefulWidget {
  const TecladoCodigo({
    super.key,
    required this.onEnviar,
    this.oscuro = false,
    this.tamanoTecla = 68,
  });

  final ValidarCodigo onEnviar;
  final bool oscuro;
  final double tamanoTecla;

  @override
  State<TecladoCodigo> createState() => _TecladoCodigoState();
}

class _TecladoCodigoState extends State<TecladoCodigo> {
  static const int _maximo = 6;
  static const int _minimo = 4;

  String _codigo = '';
  String? _error;
  int _segundos = 0;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _segundos = UsuariosController.instance.segundosBloqueo;
    _iniciarReloj();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void _iniciarReloj() {
    _reloj?.cancel();
    if (_segundos <= 0) {
      return;
    }
    _reloj = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final restantes = UsuariosController.instance.segundosBloqueo;
      setState(() => _segundos = restantes);
      if (restantes <= 0) {
        t.cancel();
      }
    });
  }

  bool get _bloqueado => _segundos > 0;

  void _tecla(String digito) {
    if (_bloqueado || _codigo.length >= _maximo) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _codigo += digito;
      _error = null;
    });
  }

  void _borrar() {
    if (_bloqueado || _codigo.isEmpty) {
      return;
    }
    setState(() => _codigo = _codigo.substring(0, _codigo.length - 1));
  }

  void _enviar() {
    if (_bloqueado) {
      return;
    }
    if (_codigo.length < _minimo) {
      setState(() => _error = 'El código tiene de 4 a 6 dígitos');
      return;
    }
    final error = widget.onEnviar(_codigo);
    if (!mounted) {
      return;
    }
    final segundos = UsuariosController.instance.segundosBloqueo;
    setState(() {
      _codigo = '';
      _segundos = segundos;
      _error = segundos > 0 ? null : error;
    });
    if (error != null) {
      HapticFeedback.mediumImpact();
    }
    _iniciarReloj();
  }

  @override
  Widget build(BuildContext context) {
    final texto = widget.oscuro ? Colors.white : AppColors.espresso;
    final tenue = widget.oscuro ? Colors.white24 : AppColors.line;
    final lleno = widget.oscuro ? AppColors.caramel : AppColors.cafe;
    final ranuras = _codigo.length < _minimo ? _minimo : _codigo.length;
    final t = widget.tamanoTecla;

    Widget tecla(String digito) => _Tecla(
          tamano: t,
          oscuro: widget.oscuro,
          onTap: _bloqueado ? null : () => _tecla(digito),
          child: Text(
            digito,
            style: TextStyle(
              fontSize: t * 0.38,
              fontWeight: FontWeight.w500,
              color: _bloqueado ? tenue : texto,
            ),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 22,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < ranuras; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _codigo.length ? lleno : Colors.transparent,
                    border: Border.all(
                      color: i < _codigo.length ? lleno : tenue,
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: Center(
            child: Text(
              _bloqueado
                  ? 'Demasiados intentos. Espera $_segundos s.'
                  : (_error ?? ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.oscuro ? const Color(0xFFFFB4A6) : AppColors.danger,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        for (final fila in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < fila.length; i++) ...[
                  if (i > 0) SizedBox(width: t * 0.32),
                  tecla(fila[i]),
                ],
              ],
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Tecla(
              tamano: t,
              oscuro: widget.oscuro,
              sinFondo: true,
              onTap: _bloqueado ? null : _borrar,
              child: Icon(Icons.backspace_outlined, color: texto, size: t * 0.34),
            ),
            SizedBox(width: t * 0.32),
            tecla('0'),
            SizedBox(width: t * 0.32),
            _Tecla(
              tamano: t,
              oscuro: widget.oscuro,
              destacada: true,
              onTap: _bloqueado ? null : _enviar,
              child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: t * 0.4),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tecla extends StatelessWidget {
  const _Tecla({
    required this.tamano,
    required this.oscuro,
    required this.onTap,
    required this.child,
    this.destacada = false,
    this.sinFondo = false,
  });

  final double tamano;
  final bool oscuro;
  final VoidCallback? onTap;
  final Widget child;
  final bool destacada;
  final bool sinFondo;

  @override
  Widget build(BuildContext context) {
    final Color fondo;
    if (destacada) {
      fondo = onTap == null ? AppColors.muted : AppColors.caramel;
    } else if (sinFondo) {
      fondo = Colors.transparent;
    } else {
      fondo = oscuro ? const Color(0x1FFFFFFF) : Colors.white;
    }

    return Material(
      color: fondo,
      shape: CircleBorder(
        side: (destacada || sinFondo || oscuro)
            ? BorderSide.none
            : const BorderSide(color: AppColors.line),
      ),
      elevation: (destacada || sinFondo || oscuro) ? 0 : 1,
      shadowColor: const Color(0x332B1810),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: tamano, height: tamano, child: Center(child: child)),
      ),
    );
  }
}
