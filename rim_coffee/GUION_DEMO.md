# Guion de demostración en vivo (≈ 9 minutos)

Antes: APK instalada (o `flutter run`), app **recién instalada** (sin datos).

**Datos:** correo `cafeteria.rim.coffe@gmail.com` · contraseña `rimcoffe_67` · beneficiario código `2468` · Luis `1357` · Ana `1470`

1. **Splash → Login**: logo y nombre con desvanecido. Mostrar el botón *Continuar con Google*.
2. **Validaciones**: login vacío, correo `ana@` → errores. *Crear mi negocio*: campos vacíos, contraseña `abcdef`, códigos que no coinciden → errores.
3. **Registro en 4 pasos**: nombre, eslogan y logo desde la galería → correo y contraseña → beneficiario con código 2468 → 6 mesas y menú de ejemplo.
4. **¿Quién atiende?**: teclado numérico; un código incorrecto muestra los intentos restantes. Entra con 2468.
5. **Usuarios**: *Mi turno → Panel del beneficiario → Usuarios → Nuevo usuario*: Luis, administrador, código 1357, permisos (sin *Ver reportes*). *Seguridad → Restablecer datos de demostración* para tener ventas.
6. **Cambiar de usuario**: *Mi turno → Cambiar de usuario* → entra Luis (1357). Mostrar "Lo que puedes hacer" y que *Panel* pide el código del beneficiario.
7. **Flujo completo**: Mesas → mesa libre → atiende Luis → *Entregar la tablet* → el cliente pide → "Devuelve la tablet" → *Soy quien atiende* + 1357 → se abre Pedidos → avanzar a Entregado → Mesas → Ver cuenta → **Cobrar** (queda "Cobra: Luis").
8. **Permisos**: quitarle a Luis el permiso *Cobrar* (Panel → Usuarios). Al cobrar, la app pide el código de alguien autorizado.
9. **Cambiar códigos y contraseña**: *Mi turno → Cambiar mi código*; *Panel → Seguridad → Cambiar contraseña*; *Usuarios → Restablecer código*.
10. **Reportes** (beneficiario): hoy, semana y mes; exportar texto.
11. **Personalización**: *Panel → Negocio*: cambiar logo y eslogan; se ve en login, menú y pantalla de código.
12. **Datos persistentes**: cerrar y abrir la app; todo sigue ahí.
