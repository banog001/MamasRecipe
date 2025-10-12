import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'pages/login.dart';
import 'pages/home.dart';
import 'pages/start.dart';
import 'pages/start2.dart';
import 'pages/start3.dart';
import 'pages/start4.dart';
import 'Dietitians/homePageDietitian.dart';

import 'Admin/firebaseOption.dart'; // Firebase options

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to use existing Firebase app if it’s already initialized
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      // App already initialized — just use existing instance
      Firebase.app();
    } else {
      rethrow;
    }
  }


  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    setupMessageListener();
    setupAppointmentListener();
  }

  /// Listen for new messages and show local notification
  void setupMessageListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // user not logged in yet

    FirebaseFirestore.instance
        .collection('messages')
        .where('receiverID', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      print("📡 Firestore snapshot triggered: ${snapshot.docChanges.length} changes");

      for (var change in snapshot.docChanges) {
        print("🔍 Change type: ${change.type}");

        if (change.type == DocumentChangeType.added) {
          var msg = change.doc.data()!;
          print("📩 Message detected: ${msg['message']}");

          flutterLocalNotificationsPlugin.show(
            msg.hashCode,
            "New message from ${msg['senderName']}",
            msg['message'],
            NotificationDetails(
              android: AndroidNotificationDetails(
                'message_channel',
                'Messages',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      }
    });
  }

  void setupAppointmentListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('notifications')
        .snapshots()
        .listen((snapshot) {
      print("📡 Appointment snapshot triggered: ${snapshot.docChanges.length} changes");

      for (var change in snapshot.docChanges) {
        print("🔍 Appointment change type: ${change.type}");

        if (change.type == DocumentChangeType.added) {
          var notif = change.doc.data();
          if (notif == null) continue;

          print("📅 Appointment notification detected: ${notif['message']}");

          flutterLocalNotificationsPlugin.show(
            notif.hashCode,
            notif['title'] ?? 'New Appointment',
            notif['message'] ?? 'You have a new appointment.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'appointment_channel',
                'Appointments',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      }
    });
  }



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

            if (role.toLowerCase() == 'dietitian') {
              return const HomePageDietitian();
            }

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
