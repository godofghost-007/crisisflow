import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyPlaceholderForWebAPIKey',
    appId: '1:1234567890:web:placeholder',
    messagingSenderId: '1234567890',
    projectId: 'crisisflow-placeholder',
    authDomain: 'crisisflow-placeholder.firebaseapp.com',
    storageBucket: 'crisisflow-placeholder.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyPlaceholderForAndroidAPIKey',
    appId: '1:1234567890:android:placeholder',
    messagingSenderId: '1234567890',
    projectId: 'crisisflow-placeholder',
    storageBucket: 'crisisflow-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyPlaceholderForiOSAPIKey',
    appId: '1:1234567890:ios:placeholder',
    messagingSenderId: '1234567890',
    projectId: 'crisisflow-placeholder',
    storageBucket: 'crisisflow-placeholder.appspot.com',
    iosBundleId: 'com.example.crisisflow',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyPlaceholderForMacOSAPIKey',
    appId: '1:1234567890:ios:placeholder',
    messagingSenderId: '1234567890',
    projectId: 'crisisflow-placeholder',
    storageBucket: 'crisisflow-placeholder.appspot.com',
    iosBundleId: 'com.example.crisisflow',
  );
}
