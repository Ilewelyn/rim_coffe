import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rim_coffee/core/nube/sincronizacion.dart';
import 'package:rim_coffee/core/services/seed_data.dart';
import 'package:rim_coffee/core/storage/esquema.dart';

void main() {
  test('las filas pasan a la nube y regresan iguales', () {
    final productos = SeedData.productos();
    final historial = SeedData.historial(productos);
    final casos = {
      Esquema.kProductos: jsonEncode([for (final p in productos) p.toJson()]),
      Esquema.kCuentas: jsonEncode([for (final c in historial.cuentas) c.toJson()]),
      Esquema.kPedidos: jsonEncode([for (final p in historial.pedidos) p.toJson()]),
    };
    for (final caso in casos.entries) {
      final filas = Esquema.aTablas(caso.key, caso.value);
      for (final t in Esquema.tablasPorClave[caso.key]!) {
        for (final local in filas[t.nombre]!) {
          final nube = FilaNube.aNube(t, local, 'negocio-1');
          expect(nube['negocio_id'], 'negocio-1');
          // En la nube los booleanos son true/false.
          for (final c in t.columnas.where((c) => c.tipo == TipoCol.booleano)) {
            expect(nube[c.nombre], anyOf(isNull, isA<bool>()));
          }
          // Simula el JSON que devuelve Supabase.
          final deVuelta = FilaNube.desdeNube(
            t,
            jsonDecode(jsonEncode(nube)) as Map<String, dynamic>,
          );
          expect(FilaNube.firma(deVuelta), FilaNube.firma(local), reason: t.nombre);
        }
      }
    }
  });

  test('un precio entero de la nube se lee como decimal', () {
    final fila = FilaNube.desdeNube(Esquema.productos, {
      'negocio_id': 'x',
      'id': 'latte',
      'precio': 65,
      'disponible': true,
      'orden': 0,
    });
    expect(fila['precio'], isA<double>());
    expect(fila['disponible'], 1);
  });

  test('solo se comparten los datos del negocio, no la sesión ni el carrito', () {
    expect(Sincronizacion.claves, isNot(contains(Esquema.kCarrito)));
    expect(Sincronizacion.claves, containsAll([Esquema.kPedidos, Esquema.kUsuarios]));
  });
}
