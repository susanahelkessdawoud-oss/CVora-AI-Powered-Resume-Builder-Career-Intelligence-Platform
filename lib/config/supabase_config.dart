/// Supabase project configuration.
///
/// Only the URL and the **publishable/anon** key belong here — this file
/// ships inside the compiled app, so anyone can read it. Both values are
/// designed to be public: real security comes from Row Level Security
/// (RLS) policies on the database tables, not from hiding this key.
///
/// The **secret key** (`sb_secret_...`) must NEVER be placed in this app.
/// It bypasses RLS entirely, so it belongs only in a trusted server /
/// Edge Function environment, never in client (mobile/web/desktop) code.
class SupabaseConfig {
  static const String url = 'https://bobayuhrningbnsrwvkg.supabase.co';
  static const String publishableKey =
      'sb_publishable_EtzSdTy3EazYaQwHAzMP7g_8LFM1Hx0';
}
