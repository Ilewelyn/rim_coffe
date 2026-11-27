# Activar "Continuar con Google"

La app ya trae el botón y el código. Solo falta decirle a Google que tu app existe.
Se hace **una vez**, es gratis y tarda unos 10 minutos. No hace falta Firebase ni el archivo `google-services.json`.

Mientras no lo configures, el botón muestra el aviso *"El inicio con Google todavía no está configurado"* y todo lo demás funciona con correo y contraseña.

## Datos que vas a necesitar

| Dato | Valor |
|---|---|
| Nombre del paquete | `com.rimcoffee.rim_coffee` |
| Huella SHA-1 de la APK compilada en GitHub | `D5:07:95:8B:42:D4:B9:EA:34:41:E9:0F:A8:0E:EC:9C:0D:3F:0A:B3` |

La huella sale de la llave fija `tool/firma/debug.keystore`, que GitHub Actions usa para firmar todas las APK. Por eso no cambia entre compilaciones.

## Pasos

1. Entra a <https://console.cloud.google.com> con tu cuenta de Google y crea un proyecto (por ejemplo *Rim Coffee*).
2. Ve a **APIs y servicios → Pantalla de consentimiento de OAuth** (en la consola nueva se llama **Google Auth Platform → Branding**):
   - Tipo de usuario: **Externo**.
   - Nombre de la app: *Rim Coffee*. Correo de asistencia: el tuyo.
   - En **Público / Usuarios de prueba** agrega los correos de Google que van a iniciar sesión (mientras la app esté "en prueba", solo esos correos pueden entrar).
3. Ve a **Credenciales → Crear credenciales → ID de cliente de OAuth**:
   - Tipo de aplicación: **Android**.
   - Nombre del paquete: `com.rimcoffee.rim_coffee`
   - Huella SHA-1: la de la tabla de arriba.
   - Guardar.
4. Espera de 5 a 10 minutos (Google tarda en activar la credencial).
5. Abre la app y toca **Continuar con Google**.

## Cómo se usa en la app

- **Negocio nuevo**: en el login toca *Continuar con Google*. Si el dispositivo no tiene negocio, se abre el registro con tu correo ya puesto. La contraseña se vuelve opcional.
- **Negocio que ya existe**: entra con correo y contraseña y ve a *Panel → Seguridad → Vincular cuenta de Google*. Desde ese momento puedes entrar con Google.
- **Olvidé mi contraseña**: si hay una cuenta de Google vinculada, también sirve para verificar que eres el dueño.

## Si compilas la APK en tu computadora

Tu computadora firma con su propia llave, así que tiene **otra huella SHA-1**. Tienes dos opciones:

- **A.** Agrega un segundo *ID de cliente de OAuth* tipo Android con la huella de tu computadora. Para verla, en Windows:
  ```
  keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android
  ```
- **B.** Usa la misma llave que GitHub: copia `tool/firma/debug.keystore` a `%USERPROFILE%\.android\debug.keystore`. Antes haz una copia de la tuya, porque otros proyectos podrían depender de ella.

Si ya habías corrido `setup.bat` con una versión anterior, borra la carpeta `android/` y vuelve a correrlo para que el paquete sea `com.rimcoffee.rim_coffee`.

## Problemas comunes

| Mensaje | Causa |
|---|---|
| "todavía no está configurado" | El paquete o la huella SHA-1 no coinciden, o todavía no pasan los 10 minutos. |
| Elige la cuenta y no pasa nada | Ese correo no está en **Usuarios de prueba** de la pantalla de consentimiento. |
| "no está vinculada a este negocio" | Entra con correo y contraseña y vincúlala en *Panel → Seguridad*. |

> Nota: la llave `tool/firma/debug.keystore` está en el repositorio para que la huella sea siempre la misma. Sirve para la escuela y para pruebas. Si algún día publicas en Play Store, crea una llave de publicación propia y no la subas al repositorio.
