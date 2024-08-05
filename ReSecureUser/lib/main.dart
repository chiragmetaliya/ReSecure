import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:resecure_user/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:resecure_user/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');
  await LocalNotificationService().init();

  // OneSignal.initialize("ea90ba2a-ba10-46d7-86c1-eaefea11961b");

// The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
//   OneSignal.Notifications.requestPermission(true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReSecure Camera',
      theme: ThemeData(
        fontFamily: 'InknutAntiqua',
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}
