import '../formato.dart';
import 'espacio.dart';

// una reserva tal como la devuelve GET /reservas/mis-reservas
class Reserva {
  final int id;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  // activa, completada o cancelada (la api lo calcula con la hora actual)
  final String estadoActual;
  final double montoTotal;
  final Espacio espacio;

  const Reserva({
    required this.id,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estadoActual,
    required this.montoTotal,
    required this.espacio,
  });

  factory Reserva.desdeJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      horaInicio: formatoHora(json['hora_inicio'] as String),
      horaFin: formatoHora(json['hora_fin'] as String),
      estadoActual: json['estado_actual'] as String,
      montoTotal: (json['monto_total'] as num).toDouble(),
      espacio: Espacio.desdeJson(json['espacio'] as Map<String, dynamic>),
    );
  }

  bool get estaActiva => estadoActual == 'activa';
  bool get estaCancelada => estadoActual == 'cancelada';
}