import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'config.dart';

Future<void> initializeFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey,
        appId: AppConfig.firebaseAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
}

