import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://njzqcftjzskwcpforwzf.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qenFjZnRqenNrd2NwZm9yd3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0ODQzMzcsImV4cCI6MjA4ODA2MDMzN30.hnbx0os7WVRZpDP9_EmxMqFH3cN0aypQg1SvBgWtEmk';

void main() async {
  print('--- Supabase Auth Connection Test ---');
  final testEmail = 'verify_connection_${DateTime.now().millisecondsSinceEpoch}@example.com';
  const testPassword = 'TestPassword123!';

  try {
    print('1. Initializing Supabase Client...');
    final supabase = SupabaseClient(_supabaseUrl, _supabaseAnonKey);

    print('2. Attempting Sign Up with $testEmail...');
    final signUpRes = await supabase.auth.signUp(
      email: testEmail,
      password: testPassword,
    );
    
    if (signUpRes.user != null) {
      print('SUCCESS: Sign Up working! User ID: ${signUpRes.user!.id}');
    } else {
      print('WARNING: Sign Up returned null user but no error.');
    }

    print('3. Attempting Sign In with $testEmail...');
    final signInRes = await supabase.auth.signInWithPassword(
      email: testEmail,
      password: testPassword,
    );

    if (signInRes.user != null) {
      print('SUCCESS: Sign In working! Session ID: ${signInRes.session?.accessToken.substring(0, 10)}...');
    } else {
      print('FAILURE: Sign In failed to return a user.');
    }

    print('4. Attempting to query database with authenticated user...');
    final dbRes = await supabase.from('food_region').select().limit(1);
    print('SUCCESS: Database query working! Result count: ${dbRes.length}');

  } catch (e) {
    print('FAILURE: Auth connection issue.');
    print('Error details: $e');
  } finally {
    print('--- Test Finished ---');
  }
}
