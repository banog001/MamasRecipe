import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebaseOption.dart'; // your Firebase web options
import 'adminLogin.dart'; // login page

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Prevent duplicate initialization
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const LoginPage(),
    );
  }
}
