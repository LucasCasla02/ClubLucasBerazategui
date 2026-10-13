import '../formato.dart';

// un horario posible de una cancha, como lo devuelve GET /espacios/{id}/horarios
class Franja {
  final String horaInicio;
  final String horaFin;
  final bool disponible;

  const Franja({required this.horaInicio, required this.horaFin, required this.disponible});

  factory Franja.desdeJson(Map<String, dynamic> json) => Franja(
        horaInicio: formatoHora(json['hora_inicio'] as String),
        horaFin: formatoHora(json['hora_fin'] as String),
        disponible: json['disponible'] as bool,
      );
}