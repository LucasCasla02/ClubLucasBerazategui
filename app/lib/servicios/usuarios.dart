import '../formato.dart';
import '../modelos/usuario.dart';
import 'api.dart';
import 'auth.dart';

// pedidos del perfil a la api, necesitan sesion iniciada
class Usuarios {
  // el perfil del usuario de la sesion
  static Future<Usuario> yo() async {
    final datos = await Api.get('/usuarios/me') as Map<String, dynamic>;
    return Usuario.desdeJson(datos);
  }

  // el email no se manda porque no se puede cambiar
  static Future<Usuario> editar({
    required String nombre,
    required String apellido,
    required String dni,
    required DateTime fechaNacimiento,
  }) async {
    final datos = await Api.put('/usuarios/me', {
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
      'fecha_nacimiento': fechaIso(fechaNacimiento),
    }) as Map<String, dynamic>;
    return Usuario.desdeJson(datos);
  }

  // la api borra el perfil, las reservas y la cuenta de firebase.
  // despues se cierra la sesion y la puerta vuelve al login
  static Future<void> eliminarCuenta() async {
    await Api.delete('/usuarios/me');
    await Auth.cerrarSesion();
  }
}