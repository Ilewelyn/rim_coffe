import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/nube/nube.dart';
import 'core/services/recordatorios.dart';
import 'core/state/app_bootstrap.dart';
import 'core/storage/app_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();
  await Nube.init();
  AppBootstrap.cargarDatos();
  AppBootstrap.conectarNube();
  runApp(const RimCoffeeApp());
  // Recordatorios en el dispositivo (mesas abiertas, pedidos sin iniciar).
  unawaited(Recordatorios.init());
}
