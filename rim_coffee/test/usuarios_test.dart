import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rim_coffee/core/models/usuario.dart';
import 'package:rim_coffee/core/state/negocio_controller.dart';
import 'package:rim_coffee/core/state/usuarios_controller.dart';
import 'package:rim_coffee/core/storage/app_storage.dart';
import 'package:rim_coffee/core/utils/formato.dart';
import 'package:rim_coffee/core/utils/seguridad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AppStorage.initMemoria();
    NegocioController.instance.cargar();
    UsuariosController.instance.cargar();
  });

  test('las contraseñas y códigos se guardan cifrados', () {
    final sal = Seguridad.nuevaSal();
    final huella = Seguridad.huella('1357', sal);
    expect(huella, isNot(contains('1357')));
    expect(Seguridad.coincide('1357', sal, huella), isTrue);
    expect(Seguridad.coincide('1358', sal, huella), isFalse);
    expect(Seguridad.coincide('1357', sal, ''), isFalse);
  });

  test('cada usuario entra con su propio código y sus permisos', () {
    final u = UsuariosController.instance;
    u.iniciarNegocio(nombre: 'laura rimbaud', codigo: '2468');
    expect(u.actual?.nombre, 'Laura Rimbaud');
    expect(u.actual?.esBeneficiario, isTrue);

    // Código repetido: no se permite.
    expect(u.crear(nombre: 'Ana', rol: Rol.administrador, codigo: '2468'), isNotNull);
    expect(
      u.crear(nombre: 'Ana', rol: Rol.administrador, codigo: '1470', permisos: {Permiso.cobrar}),
      isNull,
    );

    // El beneficiario puede ver el código del administrador, no el suyo.
    expect(u.porNombre('Ana')!.codigoVisible, '1470');
    expect(u.actual!.codigoVisible, isEmpty);

    final ana = u.verificar('1470');
    expect(ana.resultado, ResultadoPin.correcto);
    expect(ana.usuario?.nombre, 'Ana');
    expect(u.verificar('1470', soloBeneficiario: true).resultado, ResultadoPin.sinPermiso);
    expect(u.verificar('1470', permiso: Permiso.reportes).resultado, ResultadoPin.sinPermiso);
    expect(u.verificar('1470', permiso: Permiso.cobrar).resultado, ResultadoPin.correcto);
    expect(u.verificar('2468', permiso: Permiso.reportes).resultado, ResultadoPin.correcto);
  });

  test('tres códigos incorrectos bloquean el teclado', () {
    final u = UsuariosController.instance;
    u.iniciarNegocio(nombre: 'Laura', codigo: '2468');
    expect(u.verificar('0000').resultado, ResultadoPin.incorrecto);
    expect(u.verificar('0001').resultado, ResultadoPin.incorrecto);
    expect(u.verificar('0002').resultado, ResultadoPin.bloqueado);
    expect(u.verificar('2468').resultado, ResultadoPin.bloqueado);
    expect(u.segundosBloqueo, greaterThan(0));
  });

  test('cambiar el código propio pide el actual', () {
    final u = UsuariosController.instance;
    u.iniciarNegocio(nombre: 'Laura', codigo: '2468');
    final yo = u.actual!;
    expect(u.cambiarCodigo(yo, '9753', actual: '1111'), isNotNull);
    expect(u.cambiarCodigo(yo, '9753', actual: '2468'), isNull);
    expect(u.verificar('9753').usuario?.id, yo.id);
  });

  test('siempre queda al menos un beneficiario', () {
    final u = UsuariosController.instance;
    u.iniciarNegocio(nombre: 'Laura', codigo: '2468');
    final yo = u.actual!;
    expect(u.darDeBaja(yo), isNotNull);
    expect(u.editar(yo, rol: Rol.administrador), isNotNull);
  });

  test('migra la cuenta anterior de dos PIN compartidos', () {
    AppStorage.escribir(
      'rc.v2.negocio',
      jsonEncode({
        'nombre': 'Rim Coffee',
        'correo': 'cafe@correo.com',
        'contrasena': 'rimcoffe_67',
        'pinPersonal': '1357',
        'pinDueno': '2468',
      }),
    );
    final negocio = NegocioController.instance;
    negocio.cargar();
    UsuariosController.instance.cargar(anterior: negocio.negocio);
    negocio.guardarSiMigro();

    expect(negocio.contrasenaLocalCorrecta('cafe@correo.com', 'rimcoffe_67'), isTrue);
    expect(negocio.contrasenaLocalCorrecta('cafe@correo.com', 'otra'), isFalse);
    expect(AppStorage.leer('rc.v2.negocio'), isNot(contains('rimcoffe_67')));
    final dueno = UsuariosController.instance.verificar('2468').usuario;
    expect(dueno?.esBeneficiario, isTrue);
    final mostrador = UsuariosController.instance.verificar('1357').usuario;
    expect(mostrador?.rol, Rol.administrador);
  });

  test('el negocio local no guarda la contraseña (la tiene la nube)', () {
    final negocio = NegocioController.instance;
    negocio.registrar(nombre: 'Café Luna', correo: 'Luna@gmail.com', correoGoogle: 'luna@gmail.com');
    expect(negocio.correo, 'luna@gmail.com');
    expect(negocio.negocio!.contrasenaHuella, isEmpty);
    expect(negocio.correoRegistrado('LUNA@gmail.com'), isTrue);
    expect(negocio.correoRegistrado('otra@gmail.com'), isFalse);
    // Sin sesión en la nube no se considera autenticado.
    expect(negocio.estaAutenticado, isFalse);
  });

  test('fecha larga en español', () {
    expect(fechaLarga(DateTime(2026, 11, 24)), 'Martes 24 de noviembre');
  });
}
