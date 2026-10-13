// el perfil tal como lo devuelve GET /usuarios/me
class Usuario {
  final int id;
  final String email;
  final String nombre;
  final String apellido;
  final String dni;
  final DateTime fechaNacimiento;

  const Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.fechaNacimiento,
  });

  factory Usuario.desdeJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        email: json['email'] as String,
        nombre: json['nombre'] as String,
        apellido: json['apellido'] as String,
        dni: json['dni'] as String,
        fechaNacimiento: DateTime.parse(json['fecha_nacimiento'] as String),
      );

  String get nombreCompleto => '$nombre $apellido';

  // LB para el circulito del avatar
  String get iniciales {
    String primera(String texto) => texto.isEmpty ? '' : texto[0].toUpperCase();
    return '${primera(nombre)}${primera(apellido)}';
  }
}