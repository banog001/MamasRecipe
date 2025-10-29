import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'pages/login.dart';
import 'pages/home.dart';
import 'pages/start.dart';
import 'pages/start2.dart';
import 'pages/start3.dart';
import 'pages/start4.dart';
import 'Dietitians/homePageDietitian.dart';
import 'Admin/firebaseOption.dart';
import '../networkCheck/networkAware.dart';

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

  // Initialize timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Manila'));
  print("✅ Timezone initialized: Asia/Manila");

  // Initialize local notifications
  await _initializeNotifications();

  // Persistent background listeners
  _setupPersistentListeners();

  runApp(const MyApp());
}

/// Initialize local notifications
Future<void> _initializeNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const settings = InitializationSettings(android: android, iOS: ios);

  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (response) {
      print("📱 Notification tapped: ${response.payload}");
    },
  );

  print("✅ Notifications initialized successfully");
}

/// Persistent Firestore listeners
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

/// Listen for unread messages
void _setupMessageListener(String userId) {
  FirebaseFirestore.instance
      .collection('messages')
      .where('receiverID', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .listen(
        (snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final msg = snapshot.docs.first.data();
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
            ),
          ),
        );
      }
    },
    onError: (error) => print("❌ Error in message listener: $error"),
  );
}

/// Listen for appointment notifications
void _setupAppointmentListener(String userId) {
  FirebaseFirestore.instance
      .collection('Users')
      .doc(userId)
      .collection('notifications')
      .where('isRead', isEqualTo: false)
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .listen(
        (snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final notif = snapshot.docs.first.data();
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
            ),
          ),
        );
      }
    },
    onError: (error) => print("❌ Error in appointment listener: $error"),
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: NetworkAwareWidget(child: const AuthCheck()),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginPageMobile();
    }

    // ✅ Use StreamBuilder instead of FutureBuilder — auto refreshes
    return StreamBuilder<DocumentSnapshot>(
      stream:
      FirebaseFirestore.instance.collection('Users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const LoginPageMobile();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final isDeactivated = userData['deactivated'] ?? false;
        final role = (userData['role'] ?? 'user').toLowerCase();
        final tutorialStep = userData['tutorialStep'] ?? 0;
        final userId = user.uid;

        if (isDeactivated) {
          return _buildDeactivatedDialog(context);
        }

        if (role == 'dietitian') {
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
      },
    );
  }

  Widget _buildDeactivatedDialog(BuildContext context) {
    Future.microtask(() {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Account Deactivated'),
          content: const Text(
              'Your account has been deactivated. Please contact support.'),
          actions: [
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPageMobile()),
                      (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
    return const SizedBox();
  }
}
