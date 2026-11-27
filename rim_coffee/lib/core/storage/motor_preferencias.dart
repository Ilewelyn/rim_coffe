import 'package:rim_coffee/core/storage/motor_datos.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Motor sencillo de clave → valor (`shared_preferences`). Se usa en la
/// versión web y como respaldo si la base de datos no se pudiera abrir.
/// También es de donde se migran los datos de versiones anteriores.
class MotorPreferencias implements MotorDatos {
  MotorPreferencias._(this._prefs);

  final SharedPreferences _prefs;

  static Future<MotorPreferencias> abrir() async {
    return MotorPreferencias._(await SharedPreferences.getInstance());
  }

  @override
  String get nombre => 'Almacenamiento local';

  @override
  Future<Map<String, String>> cargar() async {
    final datos = <String, String>{};
    for (final clave in _prefs.getKeys()) {
      final valor = _prefs.get(clave);
      if (clave.startsWith('rc.') && valor is String) {
        datos[clave] = valor;
      }
    }
    return datos;
  }

  @override
  Future<void> escribir(String clave, String valor) async {
    await _prefs.setString(clave, valor);
  }

  @override
  Future<void> borrar(String clave) async {
    await _prefs.remove(clave);
  }

  @override
  Future<void> borrarTodo() async {
    final claves = _prefs.getKeys().where((c) => c.startsWith('rc.')).toList();
    for (final clave in claves) {
      await _prefs.remove(clave);
    }
  }

  @override
  Future<Map<String, int>> conteo() async => {};
}
