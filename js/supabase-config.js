// Your Supabase project (Project Settings → API).
// The anon key is meant to be public; the database rules in supabase/schema.sql
// only let visitors ADD an RSVP. Reading the list needs a signed-in admin.
window.SUPABASE_CONFIG = {
  url: "https://YOUR-PROJECT.supabase.co",
  anonKey: "YOUR-ANON-KEY"
};
