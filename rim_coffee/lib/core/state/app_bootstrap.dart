import 'dart:async';

import 'package:rim_coffee/core/nube/sincronizacion.dart';
import 'package:rim_coffee/core/state/carrito_controller.dart';
import 'package:rim_coffee/core/state/config_controller.dart';
import 'package:rim_coffee/core/state/negocio_controller.dart';
import 'package:rim_coffee/core/state/pedidos_controller.dart';
import 'package:rim_coffee/core/state/productos_controller.dart';
import 'package:rim_coffee/core/state/sesion_cliente.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';
import 'package:rim_coffee/core/storage/app_storage.dart';
import 'package:rim_coffee/core/storage/esquema.dart';

/// Arranque de la app: carga los datos guardados en el dispositivo.
class AppBootstrap {
  AppBootstrap._();

  /// El orden importa: los usuarios leen los PIN de la versión anterior de
  /// la cuenta, y los pedidos de ejemplo usan los productos.
  static void cargarDatos() {
    ConfigController.instance.cargar();
    final negocio = NegocioController.instance;
    negocio.cargar();
    UsuariosController.instance.cargar(anterior: negocio.negocio);
    negocio.guardarSiMigro();
    ProductosController.instance.cargar();
    PedidosController.instance.cargar();
    CarritoController.instance.cargar();
    SesionCliente.instance.cargar();
  }

  /// Conecta la base local con la nube: cada cambio local se sube y los
  /// cambios de otros dispositivos recargan las pantallas.
  static void conectarNube() {
    final sync = Sincronizacion.instance;
    AppStorage.alEscribir = sync.alEscribirLocal;
    sync.alCambiarDesdeNube = recargarClaves;
    if (NegocioController.instance.estaAutenticado) {
      unawaited(sync.iniciar());
    }
  }

  /// Vuelve a leer todo y avisa a las pantallas.
  static void recargarTodo() {
    ConfigController.instance.recargar();
    final negocio = NegocioController.instance;
    final sesion = negocio.sesionIniciada;
    negocio.recargar();
    negocio.sesionIniciada = sesion;
    UsuariosController.instance.recargar();
    ProductosController.instance.recargar();
    PedidosController.instance.recargar();
  }

  /// Recarga solo lo que cambió desde otro dispositivo.
  static void recargarClaves(Set<String> claves) {
    for (final clave in claves) {
      switch (clave) {
        case Esquema.kConfig:
          ConfigController.instance.recargar();
          break;
        case Esquema.kNegocio:
          final negocio = NegocioController.instance;
          final sesion = negocio.sesionIniciada;
          negocio.recargar();
          negocio.sesionIniciada = sesion;
          break;
        case Esquema.kUsuarios:
          UsuariosController.instance.recargar();
          break;
        case Esquema.kProductos:
          ProductosController.instance.recargar();
          break;
        case Esquema.kCuentas:
        case Esquema.kPedidos:
          PedidosController.instance.recargar();
          break;
      }
    }
  }

  /// Prepara un negocio recién registrado: mesas, menú de ejemplo o vacío,
  /// sin ventas anteriores, y el beneficiario con su código.
  static void prepararNegocioNuevo({
    required String beneficiario,
    required String codigo,
    required int mesas,
    required bool menuDeEjemplo,
  }) {
    ConfigController.instance.reiniciar();
    ConfigController.instance.fijarMesas(mesas);
    if (menuDeEjemplo) {
      ProductosController.instance.reiniciar();
    } else {
      ProductosController.instance.vaciar();
    }
    PedidosController.instance.vaciar();
    CarritoController.instance.vaciar();
    SesionCliente.instance.salir();
    UsuariosController.instance.iniciarNegocio(nombre: beneficiario, codigo: codigo);
  }

  /// Vuelve a los datos de demostración (sin tocar la cuenta ni los
  /// usuarios que ya existen; agrega a Luis y Ana de ejemplo).
  static void restablecerDemo() {
    ConfigController.instance.reiniciar();
    UsuariosController.instance.agregarDemo();
    ProductosController.instance.reiniciar();
    PedidosController.instance.reiniciar();
    CarritoController.instance.vaciar();
  }

  /// Borra todo lo guardado: la app queda como recién instalada y hay que
  /// crear la cuenta del negocio otra vez.
  static void borrarTodo() {
    AppStorage.borrarTodo();
    cargarDatos();
    UsuariosController.instance.olvidarTodo();
    NegocioController.instance.olvidarCuenta();
  }
}
