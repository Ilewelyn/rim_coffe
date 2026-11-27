import 'package:rim_coffee/core/models/linea_carrito.dart';
import 'package:rim_coffee/core/models/producto.dart';

/// Argumentos para la pantalla de detalle de producto.
/// Si [editar] viene lleno, la pantalla actualiza esa línea del carrito.
class DetalleProductoArgs {
  const DetalleProductoArgs({required this.producto, this.editar});

  final Producto producto;
  final LineaCarrito? editar;
}

/// Registro de un negocio cuando la persona ya entró a su cuenta en la
/// nube (con correo o con Google) pero todavía no tiene negocio.
class RegistroArgs {
  const RegistroArgs({required this.correo, this.correoGoogle = '', this.nombre = ''});

  final String correo;
  final String correoGoogle;
  final String nombre;
}
