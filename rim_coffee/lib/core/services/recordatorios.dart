import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rim_coffee/core/models/pedido.dart';
import 'package:rim_coffee/core/state/negocio_controller.dart';
import 'package:rim_coffee/core/state/pedidos_controller.dart';
import 'package:rim_coffee/core/storage/app_storage.dart';
import 'package:timezone/data/latest_all.dart' as tzdatos;
import 'package:timezone/timezone.dart' as tz;

/// Recordatorios en la barra de notificaciones del dispositivo (aunque la
/// app esté cerrada):
/// - Una mesa sigue abierta después de [mesaAbierta] (¿ya se cobró o se
///   puede liberar?).
/// - Un pedido sigue en "Recibido" después de [pedidoSinIniciar].
///
/// Se reprograman solos cada vez que cambian las cuentas o los pedidos (en
/// este dispositivo o desde otro). Se pueden apagar por dispositivo en
/// Mi turno.
class Recordatorios {
  Recordatorios._();

  static const Duration mesaAbierta = Duration(hours: 2);
  static const Duration pedidoSinIniciar = Duration(minutes: 15);

  /// Preferencia de este dispositivo (no se sincroniza).
  static const String _kActivos = 'rc.recordatorios';

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _listo = false;
  static Timer? _espera;

  static bool get activos => AppStorage.leer(_kActivos) != 'no';

  static Future<void> init() async {
    if (kIsWeb) {
      return;
    }
    try {
      tzdatos.initializeTimeZones();
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _listo = true;
      PedidosController.instance.addListener(_programarPronto);
      NegocioController.instance.addListener(_programarPronto);
      if (activos) {
        await pedirPermiso();
      }
      await reprogramar();
    } catch (e) {
      debugPrint('No se pudieron iniciar los recordatorios: $e');
    }
  }

  /// Pide permiso para mostrar notificaciones (Android 13 o más reciente).
  static Future<bool> pedirPermiso() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return false;
    }
    return await android.requestNotificationsPermission() ?? false;
  }

  static Future<void> cambiarActivos(bool valor) async {
    AppStorage.escribir(_kActivos, valor ? 'si' : 'no');
    if (valor) {
      await pedirPermiso();
    }
    await reprogramar();
  }

  static void _programarPronto() {
    _espera?.cancel();
    _espera = Timer(const Duration(seconds: 1), reprogramar);
  }

  static int _id(String tipo, String clave) => (('$tipo:$clave').hashCode & 0x3fffffff);

  static const NotificationDetails _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'recordatorios',
      'Recordatorios',
      channelDescription: 'Mesas abiertas por mucho tiempo y pedidos sin iniciar',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Borra los recordatorios programados y vuelve a programar los que
  /// siguen haciendo falta.
  static Future<void> reprogramar() async {
    if (!_listo) {
      return;
    }
    try {
      await _plugin.cancelAll();
      if (!activos || !NegocioController.instance.estaAutenticado) {
        return;
      }
      final ahora = DateTime.now();
      final pedidos = PedidosController.instance;

      for (final c in pedidos.cuentasAbiertas) {
        final cuando = c.abiertaEn.add(mesaAbierta);
        if (!cuando.isAfter(ahora)) {
          continue;
        }
        await _plugin.zonedSchedule(
          _id('mesa', c.id),
          'Mesa ${c.mesa} sigue abierta',
          'Lleva 2 horas abierta (atiende ${c.atendio}). ¿Ya se cobró o se puede liberar?',
          tz.TZDateTime.from(cuando, tz.UTC),
          _detalles,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      for (final p in pedidos.todos) {
        if (p.estado != EstadoPedido.recibido) {
          continue;
        }
        final cuando = p.creadoEn.add(pedidoSinIniciar);
        if (!cuando.isAfter(ahora)) {
          continue;
        }
        await _plugin.zonedSchedule(
          _id('pedido', p.id),
          'Pedido #${p.numero} sin iniciar',
          'Mesa ${p.mesa} · ${p.cliente}: lleva 15 minutos en "Recibido".',
          tz.TZDateTime.from(cuando, tz.UTC),
          _detalles,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('No se pudieron programar los recordatorios: $e');
    }
  }
}
