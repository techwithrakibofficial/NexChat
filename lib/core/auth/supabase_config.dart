abstract final class SupabaseConfig {
  // Public client configuration. Never place service-role keys here.
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://erzskhvcktygussqblbu.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_MmxYK69yA_vOYf89BwyYVA_PtCrgFoR',
  );
  static const callback = 'com.nexchat.app://auth/callback';
}
