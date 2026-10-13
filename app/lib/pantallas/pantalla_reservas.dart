import 'package:flutter/material.dart';

import '../tema.dart';
import '../widgets/titulo_doble.dart';

// provisoria, se arma en el paso 3.11
class PantallaReservas extends StatelessWidget {
  const PantallaReservas({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TituloDoble('MIS', 'RESERVAS'),
              SizedBox(height: 8),
              Text('Próximamente', style: TextStyle(color: Colores.gris)),
            ],
          ),
        ),
      ),
    );
  }
}