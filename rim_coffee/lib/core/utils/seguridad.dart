import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Cifrado de contraseñas y códigos: nunca se guardan tal cual, solo su
/// huella SHA-256 combinada con una "sal" aleatoria propia de cada dato.
class Seguridad {
  Seguridad._();

  static final Random _azar = Random.secure();

  /// Texto aleatorio para combinar con el secreto antes de cifrarlo.
  static String nuevaSal() {
    final bytes = List<int>.generate(16, (_) => _azar.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Huella del [secreto] con la [sal] indicada.
  static String huella(String secreto, String sal) {
    return sha256.convert(utf8.encode('$sal::$secreto')).toString();
  }

  /// True si [secreto] corresponde a la [huellaGuardada].
  static bool coincide(String secreto, String sal, String huellaGuardada) {
    if (huellaGuardada.isEmpty) {
      return false;
    }
    return huella(secreto, sal) == huellaGuardada;
  }

  /// Identificador corto y único (para usuarios, etc.).
  static String nuevoId() {
    final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final r = _azar.nextInt(1 << 32).toRadixString(36);
    return '$t$r';
  }
}
