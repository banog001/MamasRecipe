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

import 'Admin/firebaseOption.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      Firebase.app();
    } else {
      rethrow;
    }
  }

  // Initialize notifications BEFORE runApp
  await _initializeNotifications();

  // Setup persistent listeners
  _setupPersistentListeners();

  runApp(const MyApp());
}

/// Initialize local notifications
Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings androidInitSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: androidInitSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Notification permission is handled by AndroidManifest.xml for Android 13+
  print("✅ Notifications initialized successfully");
}

/// Setup persistent listeners that survive navigation
void _setupPersistentListeners() {
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      print("📡 User authenticated: ${user.uid}");
      _setupMessageListener(user.uid);
      _setupAppointmentListener(user.uid);
    } else {
      print("📡 User logged out");
    }
  });
}

/// Listen for new messages
void _setupMessageListener(String userId) {
  FirebaseFirestore.instance
      .collection('messages')
      .where('receiverID', isEqualTo: userId)
      .where('isRead', isEqualTo: false)  // Only unread messages
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .listen(
        (snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final msg = snapshot.docs.first.data();
        print("📩 Unread message detected: ${msg['message']}");

        flutterLocalNotificationsPlugin.show(
          msg.hashCode,
          "New message from ${msg['senderName']}",
          msg['message'],
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'message_channel',
              'Messages',
              channelDescription: 'Notifications for new messages',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: true,
            ),
          ),
        );
      }
    },
    onError: (error) {
      print("❌ Error in message listener: $error");
    },
  );
}

/// Listen for new appointments
void _setupAppointmentListener(String userId) {
  FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('notifications')
      .where('isRead', isEqualTo: false)  // Only unread notifications
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .listen(
        (snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final notif = snapshot.docs.first.data();
        print("📅 Unread appointment notification detected: ${notif['message']}");

        flutterLocalNotificationsPlugin.show(
          notif.hashCode,
          notif['title'] ?? 'New Notification',
          notif['message'] ?? 'You have a new notification',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'appointment_channel',
              'Appointments',
              channelDescription: 'Notifications for appointments',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: true,
            ),
          ),
        );
      }
    },
    onError: (error) {
      print("❌ Error in appointment listener: $error");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mama\'s Recipe',
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