import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'pantallas/pantalla_inicio.dart';
import 'pantallas/pantalla_login.dart';
import 'servicios/auth.dart';
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
        // toda la app en español, incluido el calendario
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _Puerta(),
      ),
    );
  }
}

// muestra el login o el inicio segun haya sesion iniciada
class _Puerta extends StatelessWidget {
  const _Puerta();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Auth.cambios,
      builder: (context, sesion) {
        if (sesion.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return ValueListenableBuilder<bool>(
          valueListenable: Auth.registrando,
          builder: (context, registrando, _) {
            final usuario = sesion.data;
            // mientras se crea la cuenta se sigue mostrando el login
            if (usuario == null || registrando) return const PantallaLogin();
            // la key hace que si cambia el usuario se vuelva a cargar el perfil
            return PantallaInicio(key: ValueKey(usuario.uid));
          },
        );
      },
    );
  }
}