import '../modelos/sede.dart';
import 'api.dart';

// pedidos de sedes y canchas a la api
class Catalogo {
  static Future<List<Sede>> sedes() async {
    final lista = await Api.get('/sedes') as List<dynamic>;
    return lista.map((s) => Sede.desdeJson(s as Map<String, dynamic>)).toList();
  }
}