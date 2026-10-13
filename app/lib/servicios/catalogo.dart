import '../formato.dart';
import '../modelos/espacio.dart';
import '../modelos/franja.dart';
import '../modelos/sede.dart';
import 'api.dart';

// pedidos de sedes, canchas y horarios a la api
class Catalogo {
  static Future<List<Sede>> sedes() async {
    final lista = await Api.get('/sedes') as List<dynamic>;
    return lista.map((s) => Sede.desdeJson(s as Map<String, dynamic>)).toList();
  }

  // todas las canchas activas de una sede
  static Future<List<Espacio>> espaciosDeSede(int sedeId) async {
    final lista = await Api.get('/espacios?sede_id=$sedeId') as List<dynamic>;
    return lista.map((e) => Espacio.desdeJson(e as Map<String, dynamic>)).toList();
  }

  // horarios de una cancha en una fecha, para reservas de 1 o 2 horas
  static Future<List<Franja>> horarios(int espacioId, DateTime fecha, int duracion) async {
    final datos = await Api.get(
      '/espacios/$espacioId/horarios?fecha=${fechaIso(fecha)}&duracion=$duracion',
    ) as Map<String, dynamic>;
    return (datos['franjas'] as List<dynamic>)
        .map((f) => Franja.desdeJson(f as Map<String, dynamic>))
        .toList();
  }
}