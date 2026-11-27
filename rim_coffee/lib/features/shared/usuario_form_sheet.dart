import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rim_coffee/app/theme.dart';
import 'package:rim_coffee/core/models/usuario.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';
import 'package:rim_coffee/core/utils/validadores.dart';
import 'package:rim_coffee/core/widgets/widgets.dart';

/// Alta o edición de un usuario en una hoja inferior. Devuelve true si se guardó.
///
/// Al dar de alta se pide el código (y su confirmación); al editar se
/// cambian nombre, rol y permisos (el código se cambia aparte).
Future<bool> mostrarFormularioUsuario(
  BuildContext context, {
  Usuario? usuario,
  Rol rolInicial = Rol.administrador,
  bool soloBeneficiario = false,
}) async {
  final guardado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.foam,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _UsuarioForm(
      usuario: usuario,
      rolInicial: rolInicial,
      soloBeneficiario: soloBeneficiario,
    ),
  );
  return guardado ?? false;
}

class _UsuarioForm extends StatefulWidget {
  const _UsuarioForm({
    required this.usuario,
    required this.rolInicial,
    required this.soloBeneficiario,
  });

  final Usuario? usuario;
  final Rol rolInicial;
  final bool soloBeneficiario;

  @override
  State<_UsuarioForm> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends State<_UsuarioForm> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre =
      TextEditingController(text: widget.usuario?.nombre ?? '');
  final TextEditingController _codigo = TextEditingController();
  final TextEditingController _confirmar = TextEditingController();
  late Rol _rol = widget.usuario?.rol ?? widget.rolInicial;
  late final Set<Permiso> _permisos = {...(widget.usuario?.permisos ?? permisosPorDefecto)};
  String? _error;

  bool get _editando => widget.usuario != null;

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  void _guardar() {
    setState(() => _error = null);
    if (!(_formulario.currentState?.validate() ?? false)) {
      return;
    }
    final controlador = UsuariosController.instance;
    final u = widget.usuario;
    final String? error;
    if (u == null) {
      error = controlador.crear(
        nombre: _nombre.text,
        rol: _rol,
        codigo: _codigo.text,
        permisos: _permisos,
      );
    } else {
      error = controlador.editar(u, nombre: _nombre.text, rol: _rol, permisos: _permisos);
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editando
                    ? 'Editar a ${widget.usuario!.nombre}'
                    : (widget.soloBeneficiario ? 'Crea al beneficiario' : 'Nuevo usuario'),
                style: AppText.h2,
              ),
              const SizedBox(height: 4),
              Text(
                _editando
                    ? 'Cambia su nombre, su rol o lo que puede hacer.'
                    : 'Cada persona entra con su propio código de 4 a 6 dígitos. '
                        'Así sabes quién atendió y quién cobró.',
                style: AppText.caption,
              ),
              const SizedBox(height: 16),
              RcTextField(
                label: 'Nombre',
                controller: _nombre,
                hint: 'Ej. Ana López',
                textInputAction: TextInputAction.next,
                validator: Validadores.persona,
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.muted, size: 20),
              ),
              if (!widget.soloBeneficiario) ...[
                const SizedBox(height: 16),
                const Text('Rol', style: AppText.label),
                const SizedBox(height: 8),
                SegmentedButton<Rol>(
                  segments: const [
                    ButtonSegment(
                      value: Rol.administrador,
                      icon: Icon(Icons.badge_outlined),
                      label: Text('Administrador'),
                    ),
                    ButtonSegment(
                      value: Rol.beneficiario,
                      icon: Icon(Icons.workspace_premium_outlined),
                      label: Text('Beneficiario'),
                    ),
                  ],
                  selected: {_rol},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _rol = s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: RcColores.of(context).secundario,
                    selectedForegroundColor: Colors.white,
                    foregroundColor: RcColores.of(context).secundario,
                    side: BorderSide(color: RcColores.of(context).borde),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_rol.descripcion, style: AppText.caption),
              ],
              if (!_editando) ...[
                const SizedBox(height: 16),
                CampoCodigo(
                  label: 'Código de acceso',
                  controller: _codigo,
                  hint: '4 a 6 dígitos',
                  validator: Validadores.pin,
                ),
                const SizedBox(height: 12),
                CampoCodigo(
                  label: 'Confirmar código',
                  controller: _confirmar,
                  hint: 'Repite el código',
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return 'Confirma el código';
                    }
                    if (v!.trim() != _codigo.text.trim()) {
                      return 'Los códigos no coinciden';
                    }
                    return null;
                  },
                ),
              ],
              if (_rol == Rol.administrador && !widget.soloBeneficiario) ...[
                const SizedBox(height: 18),
                const Text('Qué puede hacer además de atender', style: AppText.label),
                const SizedBox(height: 6),
                SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shadow: false,
                  child: Column(
                    children: [
                      for (final p in Permiso.values)
                        SwitchListTile(
                          value: _permisos.contains(p),
                          onChanged: (v) => setState(() {
                            if (v) {
                              _permisos.add(p);
                            } else {
                              _permisos.remove(p);
                            }
                          }),
                          activeTrackColor: RcColores.of(context).secundario,
                          title: Text(p.nombre, style: AppText.title),
                          subtitle: Text(p.detalle, style: AppText.caption),
                        ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                AvisoError(_error!),
              ],
              const SizedBox(height: 18),
              RcButton(
                label: _editando ? 'Guardar cambios' : 'Dar de alta',
                icon: _editando ? Icons.check : Icons.person_add_alt_1_outlined,
                onPressed: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cambiar el código de una persona. Con [pedirActual] primero se escribe
/// el código actual (cuando cada quien cambia el suyo). Devuelve true si se cambió.
Future<bool> mostrarCambioCodigo(
  BuildContext context,
  Usuario usuario, {
  bool pedirActual = false,
}) async {
  final cambiado = await showDialog<bool>(
    context: context,
    builder: (_) => _CambioCodigoDialog(usuario: usuario, pedirActual: pedirActual),
  );
  return cambiado ?? false;
}

class _CambioCodigoDialog extends StatefulWidget {
  const _CambioCodigoDialog({required this.usuario, required this.pedirActual});

  final Usuario usuario;
  final bool pedirActual;

  @override
  State<_CambioCodigoDialog> createState() => _CambioCodigoDialogState();
}

class _CambioCodigoDialogState extends State<_CambioCodigoDialog> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final TextEditingController _actual = TextEditingController();
  final TextEditingController _nuevo = TextEditingController();
  final TextEditingController _confirmar = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _actual.dispose();
    _nuevo.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  void _guardar() {
    setState(() => _error = null);
    if (!(_formulario.currentState?.validate() ?? false)) {
      return;
    }
    final error = UsuariosController.instance.cambiarCodigo(
      widget.usuario,
      _nuevo.text,
      actual: widget.pedirActual ? _actual.text : null,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final propio = widget.pedirActual;
    return AlertDialog(
      backgroundColor: AppColors.foam,
      title: Text(propio ? 'Cambiar mi código' : 'Código de ${widget.usuario.nombre}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (propio) ...[
                CampoCodigo(
                  label: 'Código actual',
                  controller: _actual,
                  validator: (v) => Validadores.requerido(v, 'Escribe tu código actual'),
                ),
                const SizedBox(height: 12),
              ],
              CampoCodigo(
                label: 'Código nuevo',
                controller: _nuevo,
                hint: '4 a 6 dígitos',
                validator: Validadores.pin,
              ),
              const SizedBox(height: 12),
              CampoCodigo(
                label: 'Confirmar código nuevo',
                controller: _confirmar,
                validator: (v) {
                  if ((v ?? '').trim() != _nuevo.text.trim()) {
                    return 'Los códigos no coinciden';
                  }
                  return null;
                },
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
          onPressed: _guardar,
          style: FilledButton.styleFrom(backgroundColor: RcColores.of(context).secundario),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Campo para escribir un código numérico oculto.
class CampoCodigo extends StatelessWidget {
  const CampoCodigo({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return RcTextField(
      label: label,
      controller: controller,
      hint: hint ?? '••••',
      obscure: true,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      validator: validator,
      prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.muted, size: 20),
    );
  }
}
