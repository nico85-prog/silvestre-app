// File auto-generated dalla configurazione Firebase del progetto
// silvestre-fotoservizi. Le chiavi qui dentro sono CLIENT-SIDE: sono
// pensate per essere pubbliche. La sicurezza vera è nelle Firestore
// Security Rules + Storage Rules. NON è un segreto da nascondere.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'FirebaseOptions non ancora configurate per ${defaultTargetPlatform.name}. '
          'Esegui flutterfire configure per rigenerare.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDYD22PfEgBwg9QYa3pWH1jrXO78Hj6scU',
    appId: '1:1029797648749:web:31017e2ef142a3a46b2264',
    messagingSenderId: '1029797648749',
    projectId: 'silvestre-fotoservizi',
    authDomain: 'silvestre-fotoservizi.firebaseapp.com',
    storageBucket: 'silvestre-fotoservizi.firebasestorage.app',
    measurementId: 'G-RT6X7LM4C7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD_u9Gu_E9knOHRgaDKCbFOehQHv81y58E',
    appId: '1:1029797648749:android:7ad99ddbfcf1b0066b2264',
    messagingSenderId: '1029797648749',
    projectId: 'silvestre-fotoservizi',
    storageBucket: 'silvestre-fotoservizi.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAQnkJn71Znoak5x1J19eM9d4EewrGCCuQ',
    appId: '1:1029797648749:ios:5ceb5500fa24415b6b2264',
    messagingSenderId: '1029797648749',
    projectId: 'silvestre-fotoservizi',
    storageBucket: 'silvestre-fotoservizi.firebasestorage.app',
    iosBundleId: 'com.silvestrefotoservizi.app',
  );
}
