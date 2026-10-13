import '../modelos/espacio.dart';
import '../modelos/sede.dart';
import 'api.dart';

// pedidos de sedes y canchas a la api
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
}