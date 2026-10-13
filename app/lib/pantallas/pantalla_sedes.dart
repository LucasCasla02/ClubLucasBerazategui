import 'package:flutter/material.dart';

import '../tema.dart';
import '../widgets/titulo_doble.dart';

// provisoria, se arma en el paso 3.9
class PantallaSedes extends StatelessWidget {
  const PantallaSedes({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TituloDoble('TODAS LAS', 'SEDES'),
              SizedBox(height: 8),
              Text('Próximamente', style: TextStyle(color: Colores.gris)),
            ],
          ),
        ),
      ),
    );
  }
}