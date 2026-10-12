import 'package:flutter/material.dart';

import '../tema.dart';

// cartel rojo arriba del formulario, como en el figma
class AvisoError extends StatelessWidget {
  final String mensaje;

  const AvisoError({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colores.rojo.withValues(alpha: 0.12),
        border: Border.all(color: Colores.rojo.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colores.rojo, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje, style: const TextStyle(color: Colores.rojo, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}