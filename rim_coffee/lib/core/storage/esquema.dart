import 'dart:convert';

/// Tipo de una columna de la base de datos.
enum TipoCol { texto, entero, real, booleano, json }

/// Una columna: nombre (igual al campo del modelo) y tipo.
class Col {
  const Col(this.nombre, this.tipo, {this.referencia});

  final String nombre;
  final TipoCol tipo;

  /// Llave foránea, por ejemplo `cuentas(id)`.
  final String? referencia;

  String get sql {
    final tipoSql = switch (tipo) {
      TipoCol.entero || TipoCol.booleano => 'INTEGER',
      TipoCol.real => 'REAL',
      TipoCol.texto || TipoCol.json => 'TEXT',
    };
    final ref = referencia == null ? '' : ' REFERENCES $referencia';
    return '$nombre $tipoSql$ref';
  }
}

/// Una tabla de la base de datos. Además de sus columnas, cada tabla tiene
/// `extra` (TEXT con JSON) para guardar campos nuevos o antiguos que todavía
/// no tienen columna propia, así nunca se pierde información.
class Tabla {
  const Tabla(this.nombre, this.columnas, this.llave, {this.ordenada = false});

  final String nombre;
  final List<Col> columnas;
  final List<String> llave;

  /// Las filas se guardan con una columna `orden` para respetar el orden
  /// de la lista original.
  final bool ordenada;

  String get sqlCrear {
    final partes = <String>[
      for (final c in columnas) c.sql,
      if (ordenada) 'orden INTEGER NOT NULL DEFAULT 0',
      'extra TEXT',
      'PRIMARY KEY (${llave.join(', ')})',
    ];
    return 'CREATE TABLE IF NOT EXISTS $nombre (${partes.join(', ')})';
  }

  String get ordenSql => ordenada ? 'orden' : llave.join(', ');

  /// Convierte un objeto del modelo (JSON) en una fila.
  Map<String, Object?> aFila(Map<String, dynamic> objeto, {Map<String, Object?> fijos = const {}}) {
    final fila = <String, Object?>{};
    final resto = Map<String, dynamic>.of(objeto);
    for (final c in columnas) {
      if (fijos.containsKey(c.nombre)) {
        fila[c.nombre] = fijos[c.nombre];
        resto.remove(c.nombre);
        continue;
      }
      if (!resto.containsKey(c.nombre)) {
        fila[c.nombre] = null;
        continue;
      }
      final v = resto.remove(c.nombre);
      fila[c.nombre] = _aSql(c.tipo, v);
    }
    for (final e in fijos.entries) {
      if (!fila.containsKey(e.key)) {
        fila[e.key] = e.value;
      }
    }
    fila['extra'] = resto.isEmpty ? null : jsonEncode(resto);
    return fila;
  }

  /// Convierte una fila de vuelta en el objeto JSON del modelo.
  /// [omitir] son columnas internas que no van en el objeto.
  Map<String, dynamic> desdeFila(Map<String, Object?> fila, {Set<String> omitir = const {}}) {
    final objeto = <String, dynamic>{};
    final extra = fila['extra'];
    if (extra is String && extra.isNotEmpty) {
      objeto.addAll(jsonDecode(extra) as Map<String, dynamic>);
    }
    for (final c in columnas) {
      if (omitir.contains(c.nombre)) {
        continue;
      }
      final v = _desdeSql(c.tipo, fila[c.nombre]);
      if (v != null) {
        objeto[c.nombre] = v;
      }
    }
    return objeto;
  }

  /// Texto que identifica la fila por su llave primaria.
  String llaveDe(Map<String, Object?> fila) => llave.map((k) => '${fila[k]}').join('|');

  static Object? _aSql(TipoCol tipo, Object? v) {
    if (v == null) {
      return null;
    }
    return switch (tipo) {
      TipoCol.booleano => v == true ? 1 : 0,
      TipoCol.json => jsonEncode(v),
      TipoCol.real => v is num ? v.toDouble() : v,
      TipoCol.entero || TipoCol.texto => v,
    };
  }

  static Object? _desdeSql(TipoCol tipo, Object? v) {
    if (v == null) {
      return null;
    }
    return switch (tipo) {
      TipoCol.booleano => v == 1 || v == true,
      TipoCol.json => v is String ? jsonDecode(v) : v,
      TipoCol.real => v is num ? v.toDouble() : v,
      TipoCol.entero => v is num ? v.toInt() : v,
      TipoCol.texto => v,
    };
  }
}

/// Filas de varias tablas: nombre de tabla → filas.
typedef FilasPorTabla = Map<String, List<Map<String, Object?>>>;

/// Esquema relacional de Rim Coffee (SQLite) y la conversión entre las
/// tablas y los datos que usan los controladores.
///
/// Diagrama:
/// ```
/// negocio (1)            usuarios (id)          configuracion (1)
/// categorias (id)  <──   productos (categoria)  mesas (numero)
/// cuentas (id)     <──   pedidos (cuentaId)  <── pedido_items (pedidoId)
/// productos (id)   <──   carrito (producto)     ajustes (clave → valor)
/// ```
class Esquema {
  Esquema._();

  static const int version = 1;

  static const String kNegocio = 'rc.v2.negocio';
  static const String kUsuarios = 'rc.v3.usuarios';
  static const String kConfig = 'rc.v2.config';
  static const String kProductos = 'rc.productos';
  static const String kCuentas = 'rc.v2.cuentas';
  static const String kPedidos = 'rc.v2.pedidos';
  static const String kCarrito = 'rc.carrito';

  /// Marca interna en `ajustes` que dice que una clave existe aunque sus
  /// tablas estén vacías (por ejemplo, un negocio sin pedidos todavía).
  static const String prefijoPresente = '_hay:';

  static const Tabla negocio = Tabla('negocio', [
    Col('id', TipoCol.entero),
    Col('nombre', TipoCol.texto),
    Col('correo', TipoCol.texto),
    Col('contrasenaHuella', TipoCol.texto),
    Col('sal', TipoCol.texto),
    Col('correoGoogle', TipoCol.texto),
    Col('eslogan', TipoCol.texto),
    Col('logo', TipoCol.texto),
  ], ['id']);

  static const Tabla usuarios = Tabla('usuarios', [
    Col('id', TipoCol.texto),
    Col('nombre', TipoCol.texto),
    Col('rol', TipoCol.texto),
    Col('codigo', TipoCol.texto),
    Col('sal', TipoCol.texto),
    Col('activo', TipoCol.booleano),
    Col('permisos', TipoCol.json),
    Col('creadoEn', TipoCol.texto),
  ], ['id'], ordenada: true);

  static const Tabla configuracion = Tabla('configuracion', [
    Col('id', TipoCol.entero),
    Col('telefono', TipoCol.texto),
    Col('horario', TipoCol.texto),
  ], ['id']);

  static const Tabla mesas = Tabla('mesas', [
    Col('numero', TipoCol.entero),
  ], ['numero'], ordenada: true);

  static const Tabla categorias = Tabla('categorias', [
    Col('id', TipoCol.texto),
    Col('nombre', TipoCol.texto),
    Col('conTamanos', TipoCol.booleano),
  ], ['id'], ordenada: true);

  static const Tabla productos = Tabla('productos', [
    Col('id', TipoCol.texto),
    Col('nombre', TipoCol.texto),
    Col('descripcion', TipoCol.texto),
    Col('precio', TipoCol.real),
    Col('categoria', TipoCol.texto),
    Col('imagen', TipoCol.texto),
    Col('disponible', TipoCol.booleano),
  ], ['id'], ordenada: true);

  static const Tabla cuentas = Tabla('cuentas', [
    Col('id', TipoCol.texto),
    Col('mesa', TipoCol.entero),
    Col('titular', TipoCol.texto),
    Col('atendio', TipoCol.texto),
    Col('abiertaEn', TipoCol.texto),
    Col('estado', TipoCol.texto),
    Col('cobro', TipoCol.texto),
    Col('pagadoEn', TipoCol.texto),
    Col('liberadaEn', TipoCol.texto),
    Col('total', TipoCol.real),
    Col('cambios', TipoCol.json),
  ], ['id'], ordenada: true);

  static const Tabla pedidos = Tabla('pedidos', [
    Col('id', TipoCol.texto),
    Col('numero', TipoCol.entero),
    Col('cuentaId', TipoCol.texto, referencia: 'cuentas(id)'),
    Col('ronda', TipoCol.entero),
    Col('mesa', TipoCol.entero),
    Col('cliente', TipoCol.texto),
    Col('creadoEn', TipoCol.texto),
    Col('notas', TipoCol.texto),
    Col('estado', TipoCol.texto),
    Col('nuevo', TipoCol.booleano),
    Col('entregadoEn', TipoCol.texto),
    Col('registro', TipoCol.json),
  ], ['id'], ordenada: true);

  static const Tabla pedidoItems = Tabla('pedido_items', [
    Col('pedidoId', TipoCol.texto, referencia: 'pedidos(id)'),
    Col('posicion', TipoCol.entero),
    Col('nombre', TipoCol.texto),
    Col('cantidad', TipoCol.entero),
    Col('subtotal', TipoCol.real),
    Col('detalle', TipoCol.texto),
    Col('imagen', TipoCol.texto),
  ], ['pedidoId', 'posicion']);

  static const Tabla carrito = Tabla('carrito', [
    Col('posicion', TipoCol.entero),
    Col('producto', TipoCol.texto, referencia: 'productos(id)'),
    Col('cantidad', TipoCol.entero),
    Col('tamano', TipoCol.texto),
    Col('extras', TipoCol.json),
  ], ['posicion']);

  /// Pares clave → valor para la sesión, el turno, el modo Cliente, etc.
  static const Tabla ajustes = Tabla('ajustes', [
    Col('clave', TipoCol.texto),
    Col('valor', TipoCol.texto),
  ], ['clave']);

  static const List<Tabla> tablas = [
    negocio,
    usuarios,
    configuracion,
    mesas,
    categorias,
    productos,
    cuentas,
    pedidos,
    pedidoItems,
    carrito,
    ajustes,
  ];

  /// Índices para que las consultas de reportes sean rápidas.
  static const List<String> indices = [
    'CREATE INDEX IF NOT EXISTS idx_pedidos_cuenta ON pedidos (cuentaId)',
    'CREATE INDEX IF NOT EXISTS idx_items_pedido ON pedido_items (pedidoId)',
    'CREATE INDEX IF NOT EXISTS idx_cuentas_estado ON cuentas (estado, pagadoEn)',
  ];

  /// Tablas donde se guarda cada clave (las demás claves van a `ajustes`).
  static const Map<String, List<Tabla>> tablasPorClave = {
    kNegocio: [negocio],
    kUsuarios: [usuarios],
    kConfig: [configuracion, mesas, categorias],
    kProductos: [productos],
    kCuentas: [cuentas],
    kPedidos: [pedidos, pedidoItems],
    kCarrito: [carrito],
  };

  static bool tieneTablas(String clave) => tablasPorClave.containsKey(clave);

  static List<Map<String, Object?>> _ordenadas(Tabla t, List<Map<String, dynamic>> objetos,
      [Map<String, Object?> Function(int i)? fijos]) {
    return [
      for (var i = 0; i < objetos.length; i++)
        t.aFila(objetos[i], fijos: {
          if (t.ordenada) 'orden': i,
          ...?fijos?.call(i),
        }),
    ];
  }

  static List<Map<String, dynamic>> _mapas(Object? lista) =>
      (lista as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  /// Convierte el valor JSON de una clave en filas por tabla.
  static FilasPorTabla aTablas(String clave, String valorJson) {
    final valor = jsonDecode(valorJson);
    switch (clave) {
      case kNegocio:
        return {
          'negocio': [negocio.aFila(valor as Map<String, dynamic>, fijos: {'id': 1})],
        };
      case kConfig:
        final objeto = Map<String, dynamic>.of(valor as Map<String, dynamic>);
        final listaMesas = objeto['mesas'];
        final listaCats = objeto['categorias'];
        final mesasOk = listaMesas is List && listaMesas.every((m) => m is int);
        final catsOk = listaCats is List && listaCats.every((c) => c is Map);
        if (mesasOk) {
          objeto.remove('mesas');
        }
        if (catsOk) {
          objeto.remove('categorias');
        }
        return {
          'configuracion': [configuracion.aFila(objeto, fijos: {'id': 1})],
          'mesas': mesasOk
              ? [
                  for (var i = 0; i < listaMesas.length; i++)
                    mesas.aFila({'numero': listaMesas[i]}, fijos: {'orden': i}),
                ]
              : [],
          'categorias': catsOk ? _ordenadas(categorias, listaCats.cast<Map<String, dynamic>>()) : [],
        };
      case kPedidos:
        final lista = _mapas(valor);
        final items = <Map<String, Object?>>[];
        final sinItems = <Map<String, dynamic>>[];
        for (final p in lista) {
          final copia = Map<String, dynamic>.of(p);
          final suyos = _mapas(copia.remove('items'));
          for (var j = 0; j < suyos.length; j++) {
            items.add(pedidoItems.aFila(suyos[j], fijos: {'pedidoId': p['id'], 'posicion': j}));
          }
          sinItems.add(copia);
        }
        return {'pedidos': _ordenadas(pedidos, sinItems), 'pedido_items': items};
      case kCarrito:
        final lista = _mapas(valor);
        return {
          'carrito': [
            for (var i = 0; i < lista.length; i++) carrito.aFila(lista[i], fijos: {'posicion': i}),
          ],
        };
      default:
        final t = tablasPorClave[clave]!.first;
        return {t.nombre: _ordenadas(t, _mapas(valor))};
    }
  }

  /// Arma de nuevo el JSON de una clave a partir de sus filas (ya ordenadas).
  static String desdeTablas(String clave, FilasPorTabla filas) {
    List<Map<String, Object?>> de(Tabla t) => filas[t.nombre] ?? const [];

    switch (clave) {
      case kNegocio:
        final f = de(negocio);
        return f.isEmpty ? 'null' : jsonEncode(negocio.desdeFila(f.first, omitir: {'id'}));
      case kConfig:
        final f = de(configuracion);
        final objeto = f.isEmpty
            ? <String, dynamic>{}
            : configuracion.desdeFila(f.first, omitir: {'id'});
        if (de(mesas).isNotEmpty) {
          objeto['mesas'] = [for (final m in de(mesas)) m['numero']];
        }
        if (de(categorias).isNotEmpty) {
          objeto['categorias'] = [for (final c in de(categorias)) categorias.desdeFila(c)];
        }
        return jsonEncode(objeto);
      case kPedidos:
        final porPedido = <String, List<Map<String, dynamic>>>{};
        for (final it in de(pedidoItems)) {
          porPedido
              .putIfAbsent('${it['pedidoId']}', () => [])
              .add(pedidoItems.desdeFila(it, omitir: {'pedidoId', 'posicion'}));
        }
        return jsonEncode([
          for (final p in de(pedidos))
            {...pedidos.desdeFila(p), 'items': porPedido['${p['id']}'] ?? const []},
        ]);
      case kCarrito:
        return jsonEncode([for (final c in de(carrito)) carrito.desdeFila(c, omitir: {'posicion'})]);
      default:
        final t = tablasPorClave[clave]!.first;
        return jsonEncode([for (final f in de(t)) t.desdeFila(f)]);
    }
  }
}
