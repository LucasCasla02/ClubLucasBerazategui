import 'package:flutter/material.dart';

// icono y color de cada deporte, como los chips del figma
class EstiloDeporte {
  final IconData icono;
  final Color color;

  const EstiloDeporte(this.icono, this.color);
}

EstiloDeporte estiloDeporte(String deporte) {
  switch (deporte) {
    case 'Fútbol':
      return const EstiloDeporte(Icons.sports_soccer, Color(0xFF2E9E5B));
    case 'Tenis':
      return const EstiloDeporte(Icons.sports_tennis, Color(0xFFE0703A));
    case 'Hockey':
      return const EstiloDeporte(Icons.sports_hockey, Color(0xFF7E57C2));
    case 'Vóley':
      return const EstiloDeporte(Icons.sports_volleyball, Color(0xFFE05A9B));
    case 'Golf':
      return const EstiloDeporte(Icons.sports_golf, Color(0xFF3B8FD9));
    default:
      return const EstiloDeporte(Icons.sports, Color(0xFF8A8F98));
  }
}

// chip chiquito con el icono y el nombre del deporte
class ChipDeporte extends StatelessWidget {
  final String deporte;

  const ChipDeporte(this.deporte, {super.key});

  @override
  Widget build(BuildContext context) {
    final estilo = estiloDeporte(deporte);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: estilo.color.withValues(alpha: 0.15),
        border: Border.all(color: estilo.color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(estilo.icono, size: 14, color: estilo.color),
          const SizedBox(width: 4),
          Text(deporte, style: TextStyle(fontSize: 12, color: estilo.color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}