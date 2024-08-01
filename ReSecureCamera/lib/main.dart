import 'package:flutter/material.dart';
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
// dixitnandaniya2001@gmail.com
// Dix@123@123