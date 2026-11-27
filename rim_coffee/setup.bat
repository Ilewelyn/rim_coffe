@echo off
setlocal
echo ==============================================
echo   Rim Coffee - preparando el proyecto
echo ==============================================

if not exist pubspec.yaml (
  echo ERROR: ejecuta este archivo dentro de la carpeta que tiene pubspec.yaml
  pause
  exit /b 1
)

echo.
echo [1/4] Generando carpetas de Android y web...
call flutter create --platforms=android,web --org com.rimcoffee --project-name rim_coffee .

echo.
echo [2/4] Restaurando archivos del proyecto...
copy /Y tool\pubspec_template.yaml pubspec.yaml >nul
copy /Y tool\main_template.dart lib\main.dart >nul
if exist test\widget_test.dart del test\widget_test.dart

echo.
echo [3/4] Descargando paquetes...
call flutter pub get

echo.
echo [4/4] Generando el icono y el nombre de la app...
call dart run flutter_launcher_icons
powershell -ExecutionPolicy Bypass -File tool\preparar_android.ps1

echo.
echo ==============================================
echo   Listo. Conecta tu celular por USB y ejecuta:
echo       flutter devices
echo       flutter run
echo   Para la APK:  flutter build apk --release
echo ==============================================
pause
