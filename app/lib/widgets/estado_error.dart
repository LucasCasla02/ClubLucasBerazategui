import 'package:flutter/material.dart';

import '../tema.dart';

// se muestra cuando una lista no se pudo cargar
class EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback alReintentar;

  const EstadoError({super.key, required this.mensaje, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: Colores.gris),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: Colores.gris)),
          const SizedBox(height: 8),
          TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}