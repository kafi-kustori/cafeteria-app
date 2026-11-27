/// Supabase settings come from env.json (not in Git):
///   flutter run -d chrome --dart-define-from-file=env.json
/// The anon key is public by design; Row Level Security protects the data.
/// NEVER put the service_role key here.
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
