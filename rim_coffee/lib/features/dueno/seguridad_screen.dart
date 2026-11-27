import 'package:flutter/material.dart';
import 'package:rim_coffee/app/route_names.dart';
import 'package:rim_coffee/app/theme.dart';
import 'package:rim_coffee/core/nube/acceso.dart';
import 'package:rim_coffee/core/nube/nube.dart';
import 'package:rim_coffee/core/services/google_auth.dart';
import 'package:rim_coffee/core/state/app_bootstrap.dart';
import 'package:rim_coffee/core/state/negocio_controller.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';
import 'package:rim_coffee/core/storage/app_storage.dart';
import 'package:rim_coffee/core/utils/validadores.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';
import 'package:rim_coffee/features/dueno/salir_panel.dart';
import 'package:rim_coffee/features/shared/usuario_form_sheet.dart';

/// Seguridad (solo beneficiario): mi código, contraseña de la cuenta,
/// cuenta de Google, estado de la base de datos, datos de demostración y
/// cerrar sesión.
class SeguridadScreen extends StatelessWidget {
  const SeguridadScreen({super.key});

  void _aviso(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<bool> _confirmar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required String boton,
    bool peligro = false,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: peligro ? AppColors.danger : AppColors.cafe,
            ),
            child: Text(boton),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  Future<void> _cambiarMiCodigo(BuildContext context) async {
    final yo = UsuariosController.instance.actual;
    if (yo == null) {
      return;
    }
    final ok = await mostrarCambioCodigo(context, yo, pedirActual: true);
    if (ok && context.mounted) {
      _aviso(context, 'Tu código se actualizó');
    }
  }

  Future<void> _cambiarContrasena(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ContrasenaDialog(),
    );
    if (ok == true && context.mounted) {
      _aviso(context, 'Contraseña actualizada');
    }
  }

  Future<void> _restablecer(BuildContext context) async {
    final ok = await _confirmar(
      context,
      titulo: 'Restablecer datos de demostración',
      mensaje: 'Vuelven los productos, el personal y el historial de ventas de '
          'ejemplo (y a Luis 1357 y Ana 1470 como administradores). Se pierden los '
          'pedidos y cuentas actuales. La cuenta y tus usuarios no cambian.',
      boton: 'Restablecer',
    );
    if (ok && context.mounted) {
      AppBootstrap.restablecerDemo();
      _aviso(context, 'Datos de demostración restablecidos');
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final ok = await _confirmar(
      context,
      titulo: 'Cerrar sesión',
      mensaje: 'Para volver a entrar necesitarás el correo y la contraseña (o Google) '
          'de la cuenta del negocio. Los datos se conservan en la nube.',
      boton: 'Cerrar sesión',
    );
    if (ok && context.mounted) {
      final navegador = Navigator.of(context);
      await AccesoNube.salir();
      navegador.pushNamedAndRemoveUntil(Routes.login, (ruta) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: rcAppBar(
        title: 'Seguridad',
        actions: [botonSalirPanel(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          ListenableBuilder(
            listenable: NegocioController.instance,
            builder: (context, _) {
              final negocio = NegocioController.instance;
              return _Grupo(
                titulo: 'Acceso',
                hijos: [
                  _Accion(
                    icono: Icons.pin_outlined,
                    titulo: 'Cambiar mi código',
                    detalle: 'Tu código de beneficiario (4 a 6 dígitos).',
                    onTap: () => _cambiarMiCodigo(context),
                  ),
                  _Accion(
                    icono: Icons.key_outlined,
                    titulo: Nube.tieneContrasena
                        ? 'Cambiar contraseña de la cuenta'
                        : 'Crear contraseña de la cuenta',
                    detalle: 'Con ella se inicia sesión con ${negocio.correo} en cualquier '
                        'dispositivo.',
                    onTap: () => _cambiarContrasena(context),
                  ),
                  if (GoogleAuth.disponible)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
                      child: Text(
                        'Entrar con Google: usa "Continuar con Google" con la cuenta '
                        '${negocio.correo}; se vincula sola a este negocio.',
                        style: AppText.caption,
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: Text(
                      'Los códigos de los administradores se cambian en Usuarios. '
                      'Tras 3 códigos incorrectos el teclado se bloquea 30 segundos.',
                      style: AppText.caption,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          const _BaseDatos(),
          const SizedBox(height: 14),
          _Grupo(
            titulo: 'Datos',
            hijos: [
              _Accion(
                icono: Icons.restart_alt,
                titulo: 'Restablecer datos de demostración',
                detalle: 'Productos, personal e historial de ejemplo.',
                onTap: () => _restablecer(context),
              ),
            ],
          ),
          const SizedBox(height: 18),
          RcButton(
            label: 'Cerrar sesión',
            icon: Icons.logout,
            style: RcButtonStyle.outline,
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppText.h3),
          const SizedBox(height: 8),
          ...hijos,
        ],
      ),
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
    this.peligro = false,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;
  final bool peligro;

  @override
  Widget build(BuildContext context) {
    final color = peligro ? AppColors.danger : AppColors.cafe;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icono, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: peligro ? AppColors.danger : AppColors.espresso,
                    ),
                  ),
                  Text(detalle, style: AppText.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Cambiar (o crear) la contraseña de la cuenta del negocio.
class _ContrasenaDialog extends StatefulWidget {
  const _ContrasenaDialog();

  @override
  State<_ContrasenaDialog> createState() => _ContrasenaDialogState();
}

class _ContrasenaDialogState extends State<_ContrasenaDialog> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final TextEditingController _actual = TextEditingController();
  final TextEditingController _nueva = TextEditingController();
  final TextEditingController _confirmar = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  bool _guardando = false;

  Future<void> _guardar() async {
    setState(() => _error = null);
    if (!(_formulario.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _guardando = true);
    final error = await Nube.cambiarContrasena(
      actual: Nube.tieneContrasena ? _actual.text : '',
      nueva: _nueva.text,
    );
    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() {
        _guardando = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tiene = Nube.tieneContrasena;
    return AlertDialog(
      title: Text(tiene ? 'Cambiar contraseña' : 'Crear contraseña'),
      content: SingleChildScrollView(
        child: Form(
          key: _formulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tiene) ...[
                RcPasswordField(
                  label: 'CONTRASEÑA ACTUAL',
                  controller: _actual,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validadores.requerido(v, 'Escribe tu contraseña actual'),
                ),
                const SizedBox(height: 12),
              ],
              RcPasswordField(
                label: 'NUEVA CONTRASEÑA',
                controller: _nueva,
                hint: 'Mínimo 6, con letras y números',
                textInputAction: TextInputAction.next,
                validator: Validadores.contrasena,
              ),
              const SizedBox(height: 12),
              RcPasswordField(
                label: 'CONFIRMAR CONTRASEÑA',
                controller: _confirmar,
                validator: (v) => v == _nueva.text ? null : 'Las contraseñas no coinciden',
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AvisoError(_error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: Text(_guardando ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}

/// Estado de la base de datos: motor y filas por tabla.
class _BaseDatos extends StatefulWidget {
  const _BaseDatos();

  @override
  State<_BaseDatos> createState() => _BaseDatosState();
}

class _BaseDatosState extends State<_BaseDatos> {
  late Future<Map<String, int>> _conteo = AppStorage.conteoTablas();

  static const Map<String, String> _nombres = {
    'negocio': 'Negocio',
    'usuarios': 'Usuarios',
    'configuracion': 'Configuración',
    'mesas': 'Mesas',
    'categorias': 'Categorías',
    'productos': 'Productos',
    'cuentas': 'Cuentas',
    'pedidos': 'Pedidos',
    'pedido_items': 'Productos pedidos',
    'carrito': 'Carrito',
    'ajustes': 'Ajustes',
  };

  @override
  Widget build(BuildContext context) {
    return _Grupo(
      titulo: 'Base de datos',
      hijos: [
        const EstadoNubeFila(),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.storage_rounded, color: AppColors.cafe),
            const SizedBox(width: 10),
            Expanded(child: Text(AppStorage.motor, style: AppText.title)),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: () => setState(() => _conteo = AppStorage.conteoTablas()),
              icon: const Icon(Icons.refresh, color: AppColors.muted),
            ),
          ],
        ),
        FutureBuilder<Map<String, int>>(
          future: _conteo,
          builder: (context, snap) {
            final datos = snap.data;
            if (datos == null) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              );
            }
            if (datos.isEmpty) {
              return const Text(
                'Esta versión guarda los datos en el almacenamiento local del navegador.',
                style: AppText.caption,
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in datos.entries)
                  Chip(
                    label: Text('${_nombres[e.key] ?? e.key}: ${e.value}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            'Filas por tabla en la copia de este dispositivo (SQLite). Cada cambio se '
            'guarda aquí al momento y se sube a la nube (Supabase); sin internet se '
            'sigue trabajando y se sube al volver la conexión.',
            style: AppText.caption,
          ),
        ),
      ],
    );
  }
}

