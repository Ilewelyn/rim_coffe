/// Nombres de ruta de toda la app, en un solo lugar.
class Routes {
  Routes._();

  // Acceso
  static const String splash = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperar = '/recuperar';

  /// Inicio según el modo: código de turno, Personal (normal) o Cliente
  /// (tablet entregada).
  static const String home = '/home';

  /// "¿Quién atiende?": se escribe el código personal.
  static const String turno = '/turno';

  // Modo Cliente
  static const String producto = '/producto';
  static const String devuelve = '/devuelve';

  // Modo Personal
  static const String pedidoDetalle = '/pedido';
  static const String pedidoEstado = '/pedido/estado';
  static const String cuenta = '/cuenta';

  // Panel del beneficiario (se abre con el código de un beneficiario)
  static const String dueno = '/dueno';

  /// Reportes sueltos para administradores con permiso de reportes.
  static const String reportes = '/reportes';
}
