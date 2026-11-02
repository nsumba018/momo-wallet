import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'firebase_web_options.dart';

Future<void> main() async {
  // Flutter must be ready before plugins (Firebase) can run.
  WidgetsFlutterBinding.ensureInitialized();
  // Reads google-services.json and connects the app to our Firebase project.
  // On Android the settings come from google-services.json; on the web, from the options.
  await Firebase.initializeApp(options: kIsWeb ? webFirebaseOptions : null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoMo Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      // The gate decides: login screen or wallet.
      home: const AuthGate(),
    );
  }
}
