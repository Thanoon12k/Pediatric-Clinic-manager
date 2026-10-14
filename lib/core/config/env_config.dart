/// Public Supabase project configuration is passed at build time. Never place
/// a service_role key or other privileged secret in a Flutter application.
class EnvConfig {
  EnvConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      supabaseUrl.contains('.supabase.co') &&
      supabaseAnonKey.trim().isNotEmpty;
}
