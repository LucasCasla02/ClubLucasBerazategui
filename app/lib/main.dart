import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  // firebase tiene que arrancar antes que la app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ClubApp());
}

// pantalla provisoria hasta armar el login
class ClubApp extends StatelessWidget {
  const ClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Club Lucas Berazategui',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF050508),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'CLUB',
                style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
              ),
              Text(
                'LUCAS BERAZATEGUI',
                style: TextStyle(color: Color(0xFFD4FF00), fontSize: 28, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 12),
              Text(
                'Gestión de espacios deportivos',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}