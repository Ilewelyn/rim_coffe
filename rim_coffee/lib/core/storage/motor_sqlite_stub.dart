import 'package:rim_coffee/core/storage/motor_datos.dart';

/// En la web no hay SQLite: se usa el almacenamiento local.
Future<MotorDatos?> abrirMotorSqlite({
  required Future<Map<String, String>> Function() anteriores,
}) async =>
    null;
