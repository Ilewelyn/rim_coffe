// Base de datos SQLite en Android (y escritorio); en web no existe.
export 'motor_sqlite_stub.dart' if (dart.library.io) 'motor_sqlite_io.dart';
