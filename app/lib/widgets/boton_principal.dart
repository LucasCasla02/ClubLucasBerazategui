import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema.dart';

// boton lima de ancho completo, muestra un circulito mientras carga
class BotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback? alTocar;
  final bool cargando;

  const BotonPrincipal({super.key, required this.texto, required this.alTocar, this.cargando = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: cargando ? null : alTocar,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colores.lima,
          foregroundColor: Colores.negro,
          disabledBackgroundColor: Colores.lima.withValues(alpha: 0.4),
          disabledForegroundColor: Colores.negro.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colores.negro),
              )
            : Text(texto.toUpperCase(), style: GoogleFonts.anton(fontSize: 16, letterSpacing: 1.2)),
      ),
    );
  }
}