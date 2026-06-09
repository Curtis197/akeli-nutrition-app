export const BASE_URL = __ENV.SUPABASE_URL + '/functions/v1';
export const ANON_KEY  = __ENV.SUPABASE_ANON_KEY;

export const thresholds = {
  'http_req_duration{scenario:generate_meal_plan}': ['p(95)<10000'],
  'http_req_failed{scenario:generate_meal_plan}':   ['rate<0.01'],
  'http_req_duration{scenario:batch_generate_meal_plans}': ['p(95)<60000'],
  'http_req_failed{scenario:batch_generate_meal_plans}':   ['rate<0.02'],
  'http_req_duration{scenario:ai_assistant_chat}': ['p(95)<20000'],
  'http_req_failed{scenario:ai_assistant_chat}':   ['rate<0.02'],
  'http_req_duration{scenario:analyze_meal_photo}': ['p(95)<25000'],
  'http_req_failed{scenario:analyze_meal_photo}':   ['rate<0.02'],
  'http_req_duration{scenario:toggle_recipe_like}': ['p(95)<300'],
  'http_req_failed{scenario:toggle_recipe_like}':   ['rate<0.005'],
  'http_req_duration{scenario:toggle_recipe_save}': ['p(95)<300'],
  'http_req_failed{scenario:toggle_recipe_save}':   ['rate<0.005'],
  'http_req_duration{scenario:postgrest_recipe_feed}': ['p(95)<500'],
  'http_req_failed{scenario:postgrest_recipe_feed}':   ['rate<0.005'],
  'http_req_duration{scenario:notify_group_message}': ['p(95)<1000'],
  'http_req_failed{scenario:notify_group_message}':   ['rate<0.01'],
  'http_req_duration{scenario:realtime_websocket}': ['p(95)<500'],
  'http_req_failed{scenario:realtime_websocket}':   ['rate<0.01'],
  'http_req_duration{scenario:smoke}': ['p(95)<5000'],
  'http_req_failed{scenario:smoke}':   ['rate<0.001'],
};
