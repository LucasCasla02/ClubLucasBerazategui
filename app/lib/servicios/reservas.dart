import '../formato.dart';
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
}