import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://njzqcftjzskwcpforwzf.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qenFjZnRqenNrd2NwZm9yd3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0ODQzMzcsImV4cCI6MjA4ODA2MDMzN30.hnbx0os7WVRZpDP9_EmxMqFH3cN0aypQg1SvBgWtEmk';

void main() async {
  print('--- Supabase Connection Test ---');
  
  try {
    print('Initializing Supabase Client...');
    final supabase = SupabaseClient(
      _supabaseUrl,
      _supabaseAnonKey,
    );

    print('Querying food_region table...');
    final response = await supabase
        .from('food_region')
        .select()
        .limit(5);

    if (response.isEmpty) {
      print('SUCCESS: Connected to Supabase, but the food_region table is empty.');
    } else {
      print('SUCCESS: Connected to Supabase!');
      print('Retrieved ${response.length} regions:');
      for (var item in response) {
        print(' - ${item['name_fr']} (${item['code']})');
      }
    }
  } catch (e) {
    print('FAILURE: Could not connect to Supabase.');
    print('Error: $e');
  } finally {
    // Note: Supabase.initialize doesn't have an explicit dispose for standalone scripts, 
    // but we can exit the process.
    print('--- Test Finished ---');
  }
}
