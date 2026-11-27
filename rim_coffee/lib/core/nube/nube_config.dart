/// Datos públicos del proyecto de Supabase (rim-coffee).
///
/// La llave "anon" es pública por diseño: la seguridad la dan las reglas
/// RLS de cada tabla (cada negocio solo ve sus propias filas).
class NubeConfig {
  NubeConfig._();

  /// Dirección a la que se conecta la app: el puente de Cloudflare
  /// (rim-coffee-api), que reenvía todo a Supabase. Así funciona también en
  /// redes que bloquean supabase.co.
  static const String url = 'https://rim-coffee-api.inthecloud275.workers.dev';

  /// Dirección directa del proyecto de Supabase (por si se quita el puente).
  static const String urlDirecta = 'https://xnacwcvgjqzplwmuybgh.supabase.co';

  static const String llaveAnon =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhuYWN3Y3ZnanF6cGx3bXV5YmdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTU2MjIxNzcsImV4cCI6MjExMTE5ODE3N30.O4tdyvF-uP2DrPZbxWILqB9L-wKipU3Sutvx2oSDLD4';

  /// ID de cliente de Google tipo "Aplicación web" (Google Cloud). Hace
  /// falta para entrar con Google a la nube. Vacío = Google desactivado.
  static const String googleWebClientId =
      '1097443644220-7oc5ibnfc4ngue22k7b31a2ipohdpuk1.apps.googleusercontent.com';
}
