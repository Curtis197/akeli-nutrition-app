import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'logger.dart';

const _iosClientId = '1080340252277-bk0ihbgua0a2avus25ri7os1lq0e8kti.apps.googleusercontent.com';
const _webClientId = '1080340252277-d412699vsp80741vg65draja56em44st.apps.googleusercontent.com';

String? _googleSignInRawNonce;

/// Raw nonce to pass to Supabase's `signInWithIdToken`. google_sign_in only
/// accepts a nonce at `initialize()` time (once per app session) rather than
/// per sign-in attempt, so every Google sign-in during this session reuses it.
String? get googleSignInRawNonce => _googleSignInRawNonce;

Future<void> initializeGoogleSignIn() async {
  final rawNonce = _generateRawNonce();
  final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
  _googleSignInRawNonce = rawNonce;

  if (kIsWeb) {
    // Web's GIS SDK requires a web-type OAuth client for the current page's
    // origin, and does not support serverClientId at all (the platform
    // plugin asserts on it).
    appLogger.auth('GoogleSignIn: initializing | platform: web | clientId: web');
    await GoogleSignIn.instance.initialize(
      clientId: _webClientId,
      nonce: hashedNonce,
    );
  } else {
    appLogger.auth('GoogleSignIn: initializing | platform: mobile | clientId: ios | serverClientId: web');
    await GoogleSignIn.instance.initialize(
      clientId: _iosClientId,
      serverClientId: _webClientId,
      nonce: hashedNonce,
    );
  }
  appLogger.i('✅ GoogleSignIn: initialized');
}

String _generateRawNonce([int length = 32]) {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}
