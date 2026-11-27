# ☕ Rim Coffee: mostrador digital para cafeterías

Proyecto en parejas de **Desarrollo de Aplicaciones Móviles** (UTNG), hecho con Flutter y Material 3.
Primer cliente: **Rimbaud's Coffee**. La app sirve para **cualquier cafetería**: cada negocio pone su nombre, logo, menú, mesas y usuarios.

> Los datos se guardan en una **base de datos en la nube (Supabase / PostgreSQL)**: entras con la misma cuenta en cualquier tablet o celular y ves el mismo negocio.
> Cada dispositivo guarda además una copia en **SQLite** (`rim_coffee.db`), así que sigue funcionando sin internet y sube los cambios al volver la conexión.
> Las contraseñas y los códigos se guardan cifrados (SHA-256 con sal).

---

## 1. Cómo funciona

Una tablet en el mostrador, **una cuenta por negocio** (correo y contraseña, o Google) y **un código personal por usuario**.

| Rol | Qué hace | Cómo entra |
|---|---|---|
| **Beneficiario** (dueño) | Todo: reportes, usuarios y permisos, logo y datos del negocio, menú, mesas, seguridad y respaldo | Su código. Abre el *Panel del beneficiario* |
| **Administrador** (mostrador) | Atiende: mesas, pedidos y estados. El beneficiario elige si además puede **cobrar**, **editar el menú**, **agregar o quitar mesas** o **ver reportes** | Su código |
| **Cliente** | Pide desde la tablet. No puede salir del modo Cliente | El administrador le entrega la tablet |

**Flujo de atención**

1. Se inicia sesión con la cuenta del negocio. Aparece **"¿Quién atiende?"** y la persona escribe su código.
2. *Mesas* → mesa libre → se elige quién atiende (por defecto, quien tiene el turno) → **Entregar la tablet al cliente**.
3. El cliente escribe su nombre, arma su pedido y lo envía. Aparece "Devuelve la tablet".
4. Quien atiende toca *Soy quien atiende: ver el pedido* (o mantiene presionado el logo) y escribe **su código**. La app abre **Pedidos** con su turno.
5. Cambia estados (Recibido → En preparación → Listo → Entregado) y **cobra**. Queda registrado quién atendió y quién cobró.
6. Si alguien no tiene un permiso (por ejemplo, cobrar), la app pide el código de alguien que sí lo tenga.

**Lo que cada quien puede cambiar**

- *Mi turno → Cambiar mi código*: cualquier usuario (pide el código actual).
- *Mi turno → Cambiar de usuario*: bloquea la tablet para que entre otra persona.
- *Panel → Usuarios*: altas, bajas, reactivar, rol, permisos y **restablecer códigos olvidados**.
- *Panel → Seguridad*: cambiar la contraseña de la cuenta, vincular Google, respaldo y borrar datos.
- *Panel → Negocio*: logo (desde la galería), nombre, eslogan, teléfono, horario, mesas y categorías del menú.
- *¿Olvidaste tu contraseña?* en el login: se confirma con el código del beneficiario (o con Google) y se crea una nueva.

Seguridad: códigos de 4 a 6 dígitos y **únicos por negocio** (con el código la app sabe quién eres). Con 3 códigos incorrectos el teclado se bloquea 30 segundos.

## 2. Obtener la APK

### Opción A: GitHub la compila (recomendado)

1. Sube esta carpeta a un repositorio de GitHub (rama `main`).
2. GitHub ejecuta solo el flujo **Compilar APK** (`.github/workflows/compilar-apk.yml`): revisa el código, corre las pruebas y compila.
3. Descarga `rim-coffee.apk` desde **Releases** (o *Actions → la ejecución → Artifacts*).
4. En el celular o la tablet, abre el archivo y permite "instalar apps de origen desconocido".

### Opción B: en tu computadora

1. Abre en VS Code la carpeta donde está `pubspec.yaml`.
2. En la terminal: `.\setup.bat` (genera Android y web, descarga paquetes y crea el ícono; solo una vez).
3. `flutter run` para probar con el celular conectado por USB (con *Depuración USB* activada), o
   `flutter build apk --release` → la APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

En Mac o Linux, sin `setup.bat`: `flutter create --platforms=android,web --org com.rimcoffee --project-name rim_coffee .` →
restaura `tool/main_template.dart` como `lib/main.dart` y `tool/pubspec_template.yaml` como `pubspec.yaml` →
`flutter pub get` → `dart run flutter_launcher_icons` → `flutter run`.

### Iniciar sesión con Google

Ya viene en la app. Para activarlo hay que registrar la app en Google Cloud **una vez**: sigue **[GOOGLE_LOGIN.md](GOOGLE_LOGIN.md)**.
Mientras tanto, el botón avisa que no está configurado y todo funciona con correo y contraseña.

## 3. Datos para la demostración

La app arranca sin negocio. En el login toca **Crear mi negocio** y llena los cuatro pasos:

| Dato | Valor sugerido |
|---|---|
| Negocio | `Rim Coffee` · eslogan `Arte y café` |
| Correo | `cafeteria.rim.coffe@gmail.com` |
| Contraseña | `rimcoffe_67` |
| Beneficiario | tu nombre · código `2468` |
| Mesas / menú | 6 · Menú de ejemplo |

Después, *Panel → Seguridad → Restablecer datos de demostración* carga 30 días de ventas y agrega a
**Luis (código 1357)** y **Ana (código 1470)** como administradores.

Si en la tablet ya estaba instalada la versión anterior (dos PIN compartidos), la app migra sola:
el PIN del dueño pasa a ser el código del usuario **Beneficiario** y el PIN del personal el del usuario **Mostrador**.

## 4. Capturas de pantalla

Guardadas en `screenshots/`:

| # | Archivo | Qué muestra |
|---|---|---|
| 1 | `01-splash.png` | Splashscreen |
| 2 | `02-login.png` | Login |
| 3 | `03-registro.png` | Registro (con validaciones) |
| 4 | `04-dashboard-admin.png` | Dashboard 1 — Panel del dueño (Admin) |
| 5 | `05-dashboard-cliente.png` | Dashboard 2 — Modo Cliente (menú) |
| 6 | `06-dashboard-operador.png` | Dashboard 3 — Modo Personal / Operador (Mesas) |
| 7 | `07-lista-principal.png` | Lista principal (Pedidos) |
| 8 | `08-lista-detalle.png` | Detalle de un pedido |
| 9 | `09-lista-vacia.png` | Estado vacío |
| 10 | `10-formulario.png` | Formulario (nuevo producto) |
| 11 | `11-foto-equipo.png` | Foto del equipo |
| 12 | `12-navegacion.png` | Navegación entre pantallas |

![01](screenshots/01-splash.png)
![02](screenshots/02-login.png)
![03](screenshots/03-registro.png)
![04](screenshots/04-dashboard-admin.png)
![05](screenshots/05-dashboard-cliente.png)
![06](screenshots/06-dashboard-operador.png)
![07](screenshots/07-lista-principal.png)
![08](screenshots/08-lista-detalle.png)
![09](screenshots/09-lista-vacia.png)
![10](screenshots/10-formulario.png)
![11](screenshots/11-foto-equipo.png)
![12](screenshots/12-navegacion.png)

## 5. Base de datos

**En la nube: Supabase (PostgreSQL)**, proyecto `rim-coffee`. Las mismas tablas de abajo, cada fila con `negocio_id`
(el usuario de Supabase Auth dueño de la cuenta del negocio). Reglas **RLS**: cada negocio solo puede leer y cambiar sus filas.
La cuenta del negocio (correo y contraseña, o Google) es de Supabase Auth. La función `recuperar-contrasena` (Edge Function)
cambia la contraseña si se escribe bien el código de un beneficiario (máximo 5 intentos por hora).

**Puente** (`tool/puente/worker.js`): la app no habla directo con `supabase.co` sino con un Cloudflare Worker
(`https://rim-coffee-api.inthecloud275.workers.dev`) que reenvía todo a Supabase. Así funciona aunque una red Wi-Fi bloquee supabase.co.

**Sincronización** (`lib/core/nube/sincronizacion.dart`): cada cambio local se sube en segundo plano (solo las filas que cambiaron);
los cambios de otros dispositivos llegan al momento por *Realtime* y además se revisa la nube cada 30 s y al volver a la app.
El turno, la sesión, el modo Cliente y el carrito son de cada dispositivo y no se comparten.

**En el dispositivo: SQLite** (`rim_coffee.db`, paquete `sqflite`), copia local para trabajar sin internet. El esquema está en `lib/core/storage/esquema.dart`.

| Tabla | Llave | Contenido |
|---|---|---|
| `negocio` | `id` (1) | nombre, correo, huella y sal de la contraseña, correo de Google, eslogan, logo |
| `usuarios` | `id` | nombre, rol (beneficiario/administrador), huella y sal del código, activo, permisos |
| `configuracion` | `id` (1) | teléfono, horario |
| `mesas` | `numero` | mesas del negocio |
| `categorias` | `id` | categorías del menú y si llevan tamaños |
| `productos` | `id` | nombre, descripción, precio, categoría, imagen, disponible |
| `cuentas` | `id` | cuenta de una mesa: titular, quién atendió y cobró, estado, total, fechas |
| `pedidos` | `id` | ronda de una cuenta (`cuentaId → cuentas.id`): cliente, estado, notas, fechas |
| `pedido_items` | `pedidoId, posicion` | productos de cada pedido (`pedidoId → pedidos.id`): cantidad, subtotal, detalle |
| `carrito` | `posicion` | carrito del cliente en curso (`producto → productos.id`) |
| `ajustes` | `clave` | sesión, turno y modo Cliente |

Cada tabla tiene además `extra` (JSON) para que un campo nuevo o antiguo nunca se pierda. Hay índices para cuentas por estado y pedidos por cuenta.
Al arrancar, los datos se cargan a memoria (las pantallas responden al instante) y cada cambio se escribe en la base en segundo plano, en orden y dentro de una transacción, tocando solo las filas que cambiaron.
*Panel → Seguridad → Base de datos* muestra cuántas filas tiene cada tabla. La primera vez que se abre esta versión, los datos de la versión anterior se copian solos a la base.
En la versión web (sin SQLite) se usa el almacenamiento local del navegador.

## 6. Estructura

```
lib/
├── app/        tema (tipografías DM Serif Display + Poppins), rutas con protección, app
├── core/       models (negocio, usuario, producto, pedido…) · state (ChangeNotifier) · storage
│               services (reportes, respaldo, Google, datos de ejemplo) · utils (cifrado, formato) · widgets
└── features/
    ├── auth/      splash, login (correo o Google), registro en 4 pasos, recuperar contraseña, "¿Quién atiende?"
    ├── personal/  mesas, pedidos, detalle, cuenta de mesa y cobro, mi turno
    ├── dueno/     panel del beneficiario: inicio, reportes, usuarios, negocio, seguridad
    ├── cliente/   bienvenida, menú, carrito, enviar, devolver la tablet
    └── shared/    productos, formularios de usuario y código, permisos, logo
```

Capas: presentación (`features/`) → lógica (`core/state`, `core/services`) → datos (`core/storage`: esquema SQLite y motores).
El patrón Observer es `ChangeNotifier` + `ListenableBuilder`. Pruebas en `test/` (`flutter test`).

## 7. Limitaciones

- Si dos dispositivos cambian el mismo registro al mismo tiempo, gana el último en guardarse.
- Las fotos elegidas de la galería (productos y logo) se guardan en el dispositivo donde se eligieron; en otros dispositivos se ve la imagen por defecto.
- El plan gratis de Supabase pausa el proyecto tras una semana sin uso; se reactiva desde supabase.com.
- La llave de firma `tool/firma/debug.keystore` es para pruebas. Para Play Store hace falta una llave de publicación propia.
