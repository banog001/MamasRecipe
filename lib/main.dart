import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pages/login.dart';
import 'pages/home.dart';
import 'pages/start.dart';
import 'pages/start2.dart';
import 'pages/start3.dart';
import 'pages/start4.dart';
import 'Dietitians/homePageDietitian.dart';

import 'Admin/firebaseOption.dart'; // <- firebase options file

const int TOTAL_TUTORIAL_STEPS = 4;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase safely
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (e.toString().contains('[core/duplicate-app]')) {
      // Firebase already initialized, ignore
    } else {
      rethrow; // Other errors should still crash
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mama’s Recipe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            String role = userData['role'] ?? 'user';
            int tutorialStep = userData['tutorialStep'] ?? 0;
            String userId = user.uid;

            // ✅ If role is dietitian → go directly to HomePageDietitian
            if (role.toLowerCase() == 'dietitian') {
              return const HomePageDietitian();
            }

            // ✅ Normal user flow with tutorial steps
            switch (tutorialStep) {
              case 0:
                return MealPlanningScreen(userId: userId);
              case 1:
                return MealPlanningScreen2(userId: userId);
              case 2:
                return MealPlanningScreen3(userId: userId);
              case 3:
                return MealPlanningScreen4(userId: userId);
              default:
                return const home();
            }
          }

          return const LoginPageMobile();
        },
      );
    } else {
      return const LoginPageMobile();
    }
  }
}
