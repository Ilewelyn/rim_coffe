import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rim_coffee/core/models/usuario.dart';
import 'package:rim_coffee/core/services/seed_data.dart';
import 'package:rim_coffee/core/storage/esquema.dart';

/// Quita los valores null (la base no distingue "null" de "sin dato").
Object? _sinNulos(Object? v) {
  if (v is Map) {
    return {
      for (final e in v.entries)
        if (e.value != null) e.key: _sinNulos(e.value),
    };
  }
  if (v is List) {
    return [for (final x in v) _sinNulos(x)];
  }
  return v;
}

/// Pasa un valor por las tablas y de regreso.
Object? _idaYVuelta(String clave, Object valor) {
  final filas = Esquema.aTablas(clave, jsonEncode(valor));
  return jsonDecode(Esquema.desdeTablas(clave, filas));
}

void main() {
  test('cada tabla genera su CREATE TABLE con llave primaria', () {
    for (final t in Esquema.tablas) {
      expect(t.sqlCrear, startsWith('CREATE TABLE IF NOT EXISTS ${t.nombre} ('));
      expect(t.sqlCrear, contains('PRIMARY KEY'));
    }
    expect(Esquema.pedidos.sqlCrear, contains('cuentaId TEXT REFERENCES cuentas(id)'));
  });

  test('productos, cuentas y pedidos se guardan en tablas sin perder datos', () {
    final productos = SeedData.productos();
    final historial = SeedData.historial(productos);

    final jsonProductos = [for (final p in productos) p.toJson()];
    expect(_idaYVuelta(Esquema.kProductos, jsonProductos), _sinNulos(jsonProductos));

    final jsonCuentas = [for (final c in historial.cuentas) c.toJson()];
    expect(_idaYVuelta(Esquema.kCuentas, jsonCuentas), _sinNulos(jsonCuentas));

    final jsonPedidos = [for (final p in historial.pedidos) p.toJson()];
    final filas = Esquema.aTablas(Esquema.kPedidos, jsonEncode(jsonPedidos));
    expect(filas['pedidos']!.length, jsonPedidos.length);
    expect(filas['pedido_items'], isNotEmpty);
    expect(filas['pedido_items']!.first['pedidoId'], jsonPedidos.first['id']);
    expect(_idaYVuelta(Esquema.kPedidos, jsonPedidos), _sinNulos(jsonPedidos));
  });

  test('negocio, usuarios, configuración y carrito', () {
    final negocio = {
      'nombre': 'Rim Coffee',
      'correo': 'cafe@correo.com',
      'contrasenaHuella': 'abc',
      'sal': 'xyz',
      'correoGoogle': '',
      'eslogan': 'Arte y café',
      'logo': '',
    };
    expect(_idaYVuelta(Esquema.kNegocio, negocio), negocio);

    // Campos de una versión anterior se conservan en la columna "extra".
    final anterior = {'nombre': 'X', 'correo': 'a@b.com', 'pinDueno': '2468'};
    expect(_idaYVuelta(Esquema.kNegocio, anterior), anterior);

    final usuarios = [
      Usuario(id: 'u1', nombre: 'Ana', rol: Rol.administrador, permisos: {Permiso.cobrar})
          .toJson(),
      Usuario(id: 'u2', nombre: 'Laura', rol: Rol.beneficiario).toJson(),
    ];
    final vuelta = _idaYVuelta(Esquema.kUsuarios, usuarios)! as List<dynamic>;
    expect(vuelta, usuarios);
    expect(Usuario.fromJson(vuelta.first as Map<String, dynamic>).permisos, {Permiso.cobrar});

    final config = {
      'telefono': '4181234567',
      'horario': 'Lun–Dom · 8:00–21:00',
      'mesas': [1, 2, 3, 5],
      'categorias': [
        {'id': 'frias', 'nombre': 'Frías', 'conTamanos': true},
        {'id': 'postres', 'nombre': 'Postres', 'conTamanos': false},
      ],
    };
    final filasConfig = Esquema.aTablas(Esquema.kConfig, jsonEncode(config));
    expect(filasConfig['mesas']!.length, 4);
    expect(filasConfig['categorias']!.length, 2);
    expect(_idaYVuelta(Esquema.kConfig, config), config);

    final carrito = [
      {'producto': 'capuchino', 'cantidad': 2, 'tamano': 'grande', 'extras': ['Leche de avena']},
      {'producto': 'brownie', 'cantidad': 1, 'tamano': 'mediano', 'extras': <String>[]},
    ];
    expect(_idaYVuelta(Esquema.kCarrito, carrito), carrito);
  });

  test('listas vacías siguen siendo listas', () {
    expect(_idaYVuelta(Esquema.kPedidos, []), isEmpty);
    expect(_idaYVuelta(Esquema.kProductos, []), isEmpty);
  });
}
