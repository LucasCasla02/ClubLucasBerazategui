import 'package:flutter/material.dart';

import '../tema.dart';

// foto de fondo con un oscurecido abajo para que se lea el texto
// si no hay foto usa un degradé con el color del deporte
class FondoFoto extends StatelessWidget {
  final String? foto;
  final Color colorRespaldo;
  final Widget child;

  const FondoFoto({super.key, required this.foto, required this.colorRespaldo, required this.child});

  @override
  Widget build(BuildContext context) {
    final foto = this.foto;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (foto != null)
          // cacheWidth achica la foto en memoria, en pantalla se ve igual
          Image.asset(foto, fit: BoxFit.cover, cacheWidth: 900)
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorRespaldo.withValues(alpha: 0.85), Colores.negro],
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xCC000000)],
              stops: [0.35, 1],
            ),
          ),
        ),
        child,
      ],
    );
  }
}