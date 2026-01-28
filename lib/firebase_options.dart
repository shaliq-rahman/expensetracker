import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA247N4iqOWPmEEh2zkDZGDI-R6-5axDM0',
    appId: '1:172533963248:ios:858399d1fea49120596535',
    messagingSenderId: '172533963248',
    projectId: 'expense-tracker-18599',
    storageBucket: 'expense-tracker-18599.firebasestorage.app',
    iosBundleId: 'xtrack',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAelYF1nJFj2_R_dq80df7uRoqQdp4jJyA',
    appId: '1:172533963248:android:ce121c532c511d38596535',
    messagingSenderId: '172533963248',
    projectId: 'expense-tracker-18599',
    storageBucket: 'expense-tracker-18599.firebasestorage.app',
  );
}
