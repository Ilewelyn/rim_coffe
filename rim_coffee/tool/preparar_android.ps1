# Ajustes de Android después de "flutter create" (lo llama setup.bat).
# Hace lo mismo que tool/preparar_android.py (el que usa GitHub Actions).
$m = "android\app\src\main\AndroidManifest.xml"
$t = Get-Content $m -Raw
$t = $t -replace 'android:label="rim_coffee"', 'android:label="Rim Coffee"'
foreach ($p in @("android.permission.INTERNET", "android.permission.POST_NOTIFICATIONS", "android.permission.RECEIVE_BOOT_COMPLETED")) {
  if ($t -notmatch [regex]::Escape($p)) {
    $t = ([regex]'<application').Replace($t, "<uses-permission android:name=`"$p`"/>`n    <application", 1)
  }
}
if ($t -notmatch 'ScheduledNotificationReceiver') {
  $r = @"
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            </intent-filter>
        </receiver>
    </application>
"@
  $t = ([regex]'</application>').Replace($t, $r, 1)
}
Set-Content $m $t -NoNewline

$kts = Test-Path "android\app\build.gradle.kts"
$app = if ($kts) { "android\app\build.gradle.kts" } else { "android\app\build.gradle" }
$g = Get-Content $app -Raw
if ($g -notmatch 'CoreLibraryDesugaring') {
  $activar = if ($kts) { "isCoreLibraryDesugaringEnabled = true" } else { "coreLibraryDesugaringEnabled true" }
  $g = ([regex]'compileOptions \{').Replace($g, "compileOptions {`n        $activar", 1)
  $dep = if ($kts) { 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")' } else { "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'" }
  $g = $g + "`ndependencies {`n    $dep`n}`n"
  Set-Content $app $g -NoNewline
}

$raiz = if (Test-Path "android\build.gradle.kts") { "android\build.gradle.kts" } else { "android\build.gradle" }
if (-not ((Get-Content $raiz -Raw) -match 'lintVital')) {
  Add-Content $raiz (Get-Content "tool\desactivar_lint.gradle.txt" -Raw)
}
