/// Cuenta del negocio (una por dispositivo). Sirve para iniciar sesión con
/// correo y contraseña, o con la cuenta de Google vinculada. La contraseña
/// se guarda cifrada. Nombre, eslogan y logo personalizan la app para
/// cualquier cafetería.
class Negocio {
  Negocio({
    required this.nombre,
    required this.correo,
    this.contrasenaHuella = '',
    this.sal = '',
    this.correoGoogle = '',
    this.eslogan = '',
    this.logo = '',
    this.legacyContrasena,
    this.legacyPinPersonal,
    this.legacyPinDueno,
  });

  String nombre;
  final String correo;

  /// Huella de la contraseña ('' si la cuenta se creó solo con Google).
  String contrasenaHuella;
  String sal;

  /// Correo de Google vinculado ('' si no hay).
  String correoGoogle;

  /// Frase corta que aparece en el login y en el menú del cliente.
  String eslogan;

  /// Ruta de la foto del logo elegida en la app ('' = logo por defecto).
  String logo;

  // Datos de la versión anterior (texto sin cifrar). Solo se leen una vez
  // para migrar y ya no se vuelven a guardar.
  final String? legacyContrasena;
  final String? legacyPinPersonal;
  final String? legacyPinDueno;

  bool get tieneContrasena => contrasenaHuella.isNotEmpty;
  bool get tieneGoogle => correoGoogle.isNotEmpty;

  factory Negocio.fromJson(Map<String, dynamic> json) {
    return Negocio(
      nombre: json['nombre'] as String? ?? 'Mi cafetería',
      correo: json['correo'] as String,
      contrasenaHuella: json['contrasenaHuella'] as String? ?? '',
      sal: json['sal'] as String? ?? '',
      correoGoogle: json['correoGoogle'] as String? ?? '',
      eslogan: json['eslogan'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      legacyContrasena: json['contrasena'] as String?,
      legacyPinPersonal: json['pinPersonal'] as String?,
      legacyPinDueno: json['pinDueno'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'correo': correo,
        'contrasenaHuella': contrasenaHuella,
        'sal': sal,
        'correoGoogle': correoGoogle,
        'eslogan': eslogan,
        'logo': logo,
      };
}
