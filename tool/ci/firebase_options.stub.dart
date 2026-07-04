// Stub konfigurasi Firebase untuk CI.
//
// File `lib/firebase_options.dart` yang asli di-gitignore karena berisi
// kredensial project. CI menyalin stub ini ke `lib/firebase_options.dart`
// (bila secret FIREBASE_OPTIONS_DART tidak tersedia) supaya `flutter analyze`
// dan `flutter test` bisa meng-compile aplikasi. Nilai di bawah bukan
// kredensial sungguhan dan tidak bisa dipakai terhubung ke Firebase.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'ci-stub-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'ci-stub-project',
    storageBucket: 'ci-stub-project.appspot.com',
  );
}
