// una sede tal como la devuelve GET /sedes
class Sede {
  final int id;
  final String nombre;
  final String direccion;
  final String horaApertura;
  final String horaCierre;
  final int cantidadEspacios;
  final List<String> deportes;

  const Sede({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.horaApertura,
    required this.horaCierre,
    required this.cantidadEspacios,
    required this.deportes,
  });

  // pasa el json de la api a un objeto de dart
  factory Sede.desdeJson(Map<String, dynamic> json) => Sede(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        direccion: json['direccion'] as String,
        horaApertura: json['hora_apertura'] as String,
        horaCierre: json['hora_cierre'] as String,
        cantidadEspacios: json['cantidad_espacios'] as int,
        deportes: (json['deportes'] as List<dynamic>).cast<String>(),
      );
}