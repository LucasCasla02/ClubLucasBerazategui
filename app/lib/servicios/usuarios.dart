import '../modelos/usuario.dart';
import 'api.dart';

// pedidos del perfil a la api, necesitan sesion iniciada
class Usuarios {
  // el perfil del usuario de la sesion
  static Future<Usuario> yo() async {
    final datos = await Api.get('/usuarios/me') as Map<String, dynamic>;
    return Usuario.desdeJson(datos);
  }
}