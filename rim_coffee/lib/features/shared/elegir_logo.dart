import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Abre la galería para elegir el logo del negocio. Devuelve la imagen como
/// texto ("data:image/...;base64,..."), así se guarda en la base de datos y
/// se ve en todos los dispositivos del negocio. Null si se canceló o falló.
Future<String?> elegirLogoDeGaleria(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final foto = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 320,
      maxHeight: 320,
      imageQuality: 80,
    );
    if (foto == null) {
      return null;
    }
    final bytes = await foto.readAsBytes();
    final tipo = foto.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    return 'data:image/$tipo;base64,${base64Encode(bytes)}';
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No se pudo abrir la galería. Intenta de nuevo.')),
    );
    return null;
  }
}
