import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// colores de la marca
class Colores {
  static const lima = Color(0xFFD4FF00);
  static const limaOscuro = Color(0xFF6B8000);
  static const negro = Color(0xFF050508);
  static const tarjetaOscura = Color(0xFF202022);
  static const fondoClaro = Color(0xFFF8F9FA);
  static const rojo = Color(0xFFE5383B);
  static const gris = Color(0xFF8A8F98);
}

// pone inter en cada estilo del tema respetando el grosor de cada uno
TextTheme _conInter(TextTheme t) {
  TextStyle? inter(TextStyle? s) => s == null ? null : GoogleFonts.inter(textStyle: s);
  return t.copyWith(
    displayLarge: inter(t.displayLarge),
    displayMedium: inter(t.displayMedium),
    displaySmall: inter(t.displaySmall),
    headlineLarge: inter(t.headlineLarge),
    headlineMedium: inter(t.headlineMedium),
    headlineSmall: inter(t.headlineSmall),
    titleLarge: inter(t.titleLarge),
    titleMedium: inter(t.titleMedium),
    titleSmall: inter(t.titleSmall),
    bodyLarge: inter(t.bodyLarge),
    bodyMedium: inter(t.bodyMedium),
    bodySmall: inter(t.bodySmall),
    labelLarge: inter(t.labelLarge),
    labelMedium: inter(t.labelMedium),
    labelSmall: inter(t.labelSmall),
  );
}

ThemeData _armarTema(Brightness brillo) {
  final oscuro = brillo == Brightness.dark;
  final texto = oscuro ? Colors.white : Colores.negro;
  // en modo claro el lima no se lee sobre blanco, por eso usa el lima oscuro
  final acento = oscuro ? Colores.lima : Colores.limaOscuro;

  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: oscuro ? Colores.negro : Colores.fondoClaro,
    colorScheme: ColorScheme(
      brightness: brillo,
      primary: Colores.lima,
      onPrimary: Colores.negro,
      secondary: acento,
      onSecondary: oscuro ? Colores.negro : Colors.white,
      error: Colores.rojo,
      onError: Colors.white,
      surface: oscuro ? Colores.tarjetaOscura : Colors.white,
      onSurface: texto,
    ),
  );

  return base.copyWith(
    textTheme: _conInter(base.textTheme).apply(bodyColor: texto, displayColor: texto),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: acento)),
  );
}

final temaClaro = _armarTema(Brightness.light);
final temaOscuro = _armarTema(Brightness.dark);

// titulos grandes en mayuscula, como en el figma
TextStyle estiloTitulo(double tamano, Color color) =>
    GoogleFonts.anton(fontSize: tamano, color: color, letterSpacing: 0.5);

// codigos de cancha tipo Moron_Rivadavia_17500_Futbol_F5_1
TextStyle estiloCodigo(Color color) => GoogleFonts.jetBrainsMono(fontSize: 11, color: color);

// modo claro u oscuro, arranca en oscuro y se guarda en el celular
final modoTema = ValueNotifier<ThemeMode>(ThemeMode.dark);

Future<void> cargarModoTema() async {
  final guardado = await SharedPreferencesAsync().getString('modo_tema');
  if (guardado == 'claro') modoTema.value = ThemeMode.light;
}

Future<void> cambiarModoTema(bool oscuro) async {
  modoTema.value = oscuro ? ThemeMode.dark : ThemeMode.light;
  await SharedPreferencesAsync().setString('modo_tema', oscuro ? 'oscuro' : 'claro');
}