/// Dónde se guardan físicamente los datos. La app trabaja con un caché en
/// memoria (lectura inmediata) y el motor escribe en segundo plano.
abstract class MotorDatos {
  /// Nombre para mostrar (por ejemplo "SQLite").
  String get nombre;

  /// Lee todo lo guardado: clave → valor JSON.
  Future<Map<String, String>> cargar();

  Future<void> escribir(String clave, String valor);

  Future<void> borrar(String clave);

  Future<void> borrarTodo();

  /// Filas por tabla (vacío si el motor no usa tablas).
  Future<Map<String, int>> conteo();
}

/// Motor que no guarda nada en disco (pruebas automáticas).
class MotorMemoria implements MotorDatos {
  @override
  String get nombre => 'Memoria';

  @override
  Future<Map<String, String>> cargar() async => {};

  @override
  Future<void> escribir(String clave, String valor) async {}

  @override
  Future<void> borrar(String clave) async {}

  @override
  Future<void> borrarTodo() async {}

  @override
  Future<Map<String, int>> conteo() async => {};
}
