import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDp74MbnqaVPXILuCijtu1gfyDBpbJZb1o",
            authDomain: "afro-health-oyks8y.firebaseapp.com",
            projectId: "afro-health-oyks8y",
            storageBucket: "afro-health-oyks8y.firebasestorage.app",
            messagingSenderId: "1080340252277",
            appId: "1:1080340252277:web:78d7eb0d1defcdcfea5a3c"));
  } else {
    await Firebase.initializeApp();
  }
}
