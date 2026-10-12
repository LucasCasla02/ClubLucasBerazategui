import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pantallas/pantalla_muestra.dart';
import 'tema.dart';

Future<void> main() async {
  // firebase y el modo guardado se cargan antes de mostrar la app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await cargarModoTema();
  runApp(const ClubApp());
}

class ClubApp extends StatelessWidget {
  const ClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // se redibuja toda la app cuando cambia el modo claro u oscuro
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: modoTema,
      builder: (context, modo, _) => MaterialApp(
        title: 'Club Lucas Berazategui',
        debugShowCheckedModeBanner: false,
        theme: temaClaro,
        darkTheme: temaOscuro,
        themeMode: modo,
        home: const PantallaMuestra(),
      ),
    );
  }
}