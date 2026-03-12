import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseConfig {
  static Future<void> initializeFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCxD8lxZKShbPWZYwm4zxTLXU7XYj00Uoo',
        appId: '1:996171163421:android:925d7f86cb95aa7da3e3f4',
        messagingSenderId: '996171163421',
        projectId: 'nxtgen-cart',
        storageBucket: 'nxtgen-cart.firebasestorage.app',
        databaseURL: 'https://nxtgen-cart-default-rtdb.firebaseio.com',
      ),
    );
  }
}
