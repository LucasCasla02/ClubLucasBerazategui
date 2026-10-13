import '../formato.dart';
import '../modelos/reserva.dart';
import 'api.dart';

// pedidos de reservas a la api, necesitan sesion iniciada
class Reservas {
  static Future<void> crear({
    required int espacioId,
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
  }) async {
    await Api.post('/reservas', {
      'espacio_id': espacioId,
      'fecha': fechaIso(fecha),
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
    });
  }

  // proximas: las activas que no terminaron, de la mas cercana a la mas lejana
  static Future<List<Reserva>> proximas() => _mias('proximas');

  // historial: todas (activas, completadas y canceladas), de la mas nueva a la mas vieja
  static Future<List<Reserva>> historial() => _mias('historial');

  static Future<List<Reserva>> _mias(String tipo) async {
    final lista = await Api.get('/reservas/mis-reservas?tipo=$tipo') as List<dynamic>;
    return lista.map((r) => Reserva.desdeJson(r as Map<String, dynamic>)).toList();
  }

  // el horario vuelve a quedar libre para otros
  static Future<void> cancelar(int reservaId) async {
    await Api.delete('/reservas/$reservaId');
  }
}