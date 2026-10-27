// Supabase connection for the DXP+ performance tracker.
// The publishable key is meant to be public: it can only read what Row Level Security allows
// (here: SELECT on performance_data). Never put the secret / service_role key in this file.
window.TRACKER_CONFIG = {
  supabaseUrl: 'https://mqoifnkckinqsbvrqicu.supabase.co',
  supabaseKey: 'sb_publishable_j8Kyr-1NGd0KljDcFIv0rw_ADbLOarp',
  table: 'performance_data',
};
