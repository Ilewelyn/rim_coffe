/// Roles de quien usa la app en el negocio.
///
/// - [beneficiario]: el dueño. Tiene acceso a todo: reportes, usuarios,
///   ajustes del negocio, seguridad y respaldo.
/// - [administrador]: quien atiende el mostrador: mesas, pedidos y cobro.
///   El beneficiario decide qué más puede hacer (ver [Permiso]).
///
/// El cliente no es un usuario: solo usa la tablet en modo Cliente.
enum Rol { beneficiario, administrador }

extension RolTexto on Rol {
  String get nombre => switch (this) {
        Rol.beneficiario => 'Beneficiario',
        Rol.administrador => 'Administrador',
      };

  String get descripcion => switch (this) {
        Rol.beneficiario => 'Dueño: reportes, usuarios y todos los ajustes',
        Rol.administrador => 'Atiende mesas, pedidos y clientes',
      };
}

/// Lo que un administrador puede hacer además de atender. El beneficiario
/// siempre puede todo.
enum Permiso { cobrar, menu, mesas, reportes }

extension PermisoTexto on Permiso {
  String get nombre => switch (this) {
        Permiso.cobrar => 'Cobrar y liberar mesas',
        Permiso.menu => 'Editar menú y productos',
        Permiso.mesas => 'Agregar y quitar mesas',
        Permiso.reportes => 'Ver reportes de ventas',
      };

  String get detalle => switch (this) {
        Permiso.cobrar => 'Marcar cuentas como pagadas o liberar una mesa sin cobrar.',
        Permiso.menu => 'Crear, editar y borrar productos y sus fotos.',
        Permiso.mesas => 'Cambiar cuántas mesas tiene el negocio.',
        Permiso.reportes => 'Ventas del día, semana y mes.',
      };
}

/// Permisos con los que nace un administrador nuevo.
const Set<Permiso> permisosPorDefecto = {Permiso.cobrar, Permiso.menu};

/// Una persona del negocio con su propio código de acceso (4 a 6 dígitos).
/// El código se guarda cifrado ([codigoHuella] + [sal]).
class Usuario {
  Usuario({
    required this.id,
    required this.nombre,
    required this.rol,
    this.codigoHuella = '',
    this.sal = '',
    this.activo = true,
    this.codigoVisible = '',
    Set<Permiso>? permisos,
    DateTime? creadoEn,
  })  : permisos = permisos ?? {...permisosPorDefecto},
        creadoEn = creadoEn ?? DateTime.now();

  final String id;
  String nombre;
  Rol rol;
  String codigoHuella;
  String sal;

  /// Falso cuando el beneficiario lo da de baja (se conserva en reportes).
  bool activo;

  /// Código de un administrador, para que el beneficiario lo pueda ver
  /// ('' si no se conoce). El de los beneficiarios nunca se guarda así.
  String codigoVisible;
  Set<Permiso> permisos;
  final DateTime creadoEn;

  bool get esBeneficiario => rol == Rol.beneficiario;
  bool get tieneCodigo => codigoHuella.isNotEmpty;

  /// Iniciales para el avatar ("Ana López" -> "AL").
  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) {
      return '?';
    }
    if (partes.length == 1) {
      return partes.first[0].toUpperCase();
    }
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  bool puede(Permiso permiso) => esBeneficiario || permisos.contains(permiso);

  factory Usuario.fromJson(Map<String, dynamic> j) {
    final rolTexto = j['rol'] as String? ?? 'administrador';
    final lista = (j['permisos'] as List<dynamic>?) ?? const [];
    final permisos = <Permiso>{};
    for (final p in lista) {
      for (final valor in Permiso.values) {
        if (valor.name == p) {
          permisos.add(valor);
        }
      }
    }
    return Usuario(
      id: j['id'] as String,
      nombre: j['nombre'] as String,
      rol: rolTexto == 'beneficiario' ? Rol.beneficiario : Rol.administrador,
      codigoHuella: j['codigo'] as String? ?? '',
      sal: j['sal'] as String? ?? '',
      activo: j['activo'] as bool? ?? true,
      codigoVisible: j['codigoVisible'] as String? ?? '',
      permisos: permisos,
      creadoEn: DateTime.tryParse(j['creadoEn'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'rol': rol.name,
        'codigo': codigoHuella,
        'sal': sal,
        'activo': activo,
        if (codigoVisible.isNotEmpty) 'codigoVisible': codigoVisible,
        'permisos': permisos.map((p) => p.name).toList(),
        'creadoEn': creadoEn.toIso8601String(),
      };
}
