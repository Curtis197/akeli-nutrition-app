import 'package:supabase_flutter/supabase_flutter.dart';

/// Point d'accès unique au client Supabase dans toute l'app.
/// Initialisé dans main.dart via Supabase.initialize().
SupabaseClient get supabase => Supabase.instance.client;

/// Raccourcis utiles
String? get currentUserId => supabase.auth.currentUser?.id;
bool get isAuthenticated => supabase.auth.currentUser != null;
