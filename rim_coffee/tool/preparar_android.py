"""Ajustes del proyecto Android después de "flutter create" (los usa GitHub Actions).

- Nombre visible "Rim Coffee" y permisos (internet, notificaciones, reinicio).
- Receptores para que los recordatorios programados sobrevivan a reinicios.
- Desugaring de Java (lo pide flutter_local_notifications).
- Sin "lintVital" en release (falla por un error de la herramienta).
"""
import os

MANIFEST = "android/app/src/main/AndroidManifest.xml"
PERMISOS = [
    "android.permission.INTERNET",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
]
RECEPTORES = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""

m = open(MANIFEST, encoding="utf-8").read()
m = m.replace('android:label="rim_coffee"', 'android:label="Rim Coffee"')
for permiso in PERMISOS:
    if permiso not in m:
        m = m.replace("<application", f'<uses-permission android:name="{permiso}"/>\n    <application', 1)
if "ScheduledNotificationReceiver" not in m:
    m = m.replace("</application>", RECEPTORES + "    </application>", 1)
open(MANIFEST, "w", encoding="utf-8").write(m)

kts = os.path.exists("android/app/build.gradle.kts")
app = "android/app/build.gradle.kts" if kts else "android/app/build.gradle"
g = open(app, encoding="utf-8").read()
if "CoreLibraryDesugaring" not in g:
    activar = "isCoreLibraryDesugaringEnabled = true" if kts else "coreLibraryDesugaringEnabled true"
    g = g.replace("compileOptions {", "compileOptions {\n        " + activar, 1)
    dep = ('coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")' if kts
           else "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'")
    g += "\ndependencies {\n    " + dep + "\n}\n"
open(app, "w", encoding="utf-8").write(g)

raiz = "android/build.gradle.kts" if os.path.exists("android/build.gradle.kts") else "android/build.gradle"
r = open(raiz, encoding="utf-8").read()
if "lintVital" not in r:
    r += open("tool/desactivar_lint.gradle.txt", encoding="utf-8").read()
open(raiz, "w", encoding="utf-8").write(r)
print("Android listo:", app)
