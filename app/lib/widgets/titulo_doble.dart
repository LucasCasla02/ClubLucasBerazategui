import 'package:flutter/material.dart';

import '../tema.dart';

// titulo de dos colores como en el figma, por ejemplo MIS + RESERVAS
class TituloDoble extends StatelessWidget {
  final String primera;
  final String segunda;
  final double tamano;

  const TituloDoble(this.primera, this.segunda, {super.key, this.tamano = 40});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$primera ', style: estiloTitulo(tamano, colores.onSurface)),
          TextSpan(text: segunda, style: estiloTitulo(tamano, colores.secondary)),
        ],
      ),
    );
  }
}