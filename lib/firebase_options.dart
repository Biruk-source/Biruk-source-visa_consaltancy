// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
///
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
        return windows;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDoVXyRuySmTpUAgtIlWSXZxzOsOQE5aMY',
    appId: '1:771403133672:android:d80c454d7c8baded628f5d',
    messagingSenderId: '771403133672',
    projectId: 'visa-consultancy-cbe66',
    storageBucket: 'visa-consultancy-cbe66.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCAMGsrjD6xL5z4JBbG10EOsje85UcmAuE',
    appId: '1:771403133672:ios:05f8af7803bba77b628f5d',
    messagingSenderId: '771403133672',
    projectId: 'visa-consultancy-cbe66',
    storageBucket: 'visa-consultancy-cbe66.firebasestorage.app',
    iosBundleId: 'com.example.visaConsaltancy',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD37FWkEL3ONa3U-Siq38YO1KbDIEKKWN0',
    appId: '1:528925798619:web:efea5be973136921f05cfe',
    messagingSenderId: '528925798619',
    projectId: 'visaconsaltancy-e6fdd',
    authDomain: 'visaconsaltancy-e6fdd.firebaseapp.com',
    storageBucket: 'visaconsaltancy-e6fdd.firebasestorage.app',
    measurementId: 'G-SMH5ZPMGKG',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCafkjaV0JrofmKeg4cDwagpDjqHX90E7I',
    appId: '1:528925798619:ios:ab07525ffacebbdff05cfe',
    messagingSenderId: '528925798619',
    projectId: 'visaconsaltancy-e6fdd',
    storageBucket: 'visaconsaltancy-e6fdd.firebasestorage.app',
    iosBundleId: 'com.example.visaConsaltancy',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD37FWkEL3ONa3U-Siq38YO1KbDIEKKWN0',
    appId: '1:528925798619:web:087c80d0e9da73cbf05cfe',
    messagingSenderId: '528925798619',
    projectId: 'visaconsaltancy-e6fdd',
    authDomain: 'visaconsaltancy-e6fdd.firebaseapp.com',
    storageBucket: 'visaconsaltancy-e6fdd.firebasestorage.app',
    measurementId: 'G-WLV0J2FF9E',
  );
}
