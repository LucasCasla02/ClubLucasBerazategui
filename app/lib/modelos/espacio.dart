// una cancha tal como la devuelve GET /espacios
class Espacio {
  final int id;
  final String nombre;
  final String variante;
  final int numero;
  final String ambiente;
  final bool iluminada;
  final double precioPorHora;
  final String horaApertura;
  final String horaCierre;
  final int deporteId;
  final String deporte;
  final int sedeId;
  final String sede;

  const Espacio({
    required this.id,
    required this.nombre,
    required this.variante,
    required this.numero,
    required this.ambiente,
    required this.iluminada,
    required this.precioPorHora,
    required this.horaApertura,
    required this.horaCierre,
    required this.deporteId,
    required this.deporte,
    required this.sedeId,
    required this.sede,
  });

  // pasa el json de la api a un objeto de dart
  factory Espacio.desdeJson(Map<String, dynamic> json) {
    final deporte = json['deporte'] as Map<String, dynamic>;
    final sede = json['sede'] as Map<String, dynamic>;
    return Espacio(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      variante: json['variante'] as String,
      numero: json['numero'] as int,
      ambiente: json['ambiente'] as String,
      iluminada: json['iluminada'] as bool,
      precioPorHora: (json['precio_por_hora'] as num).toDouble(),
      horaApertura: json['hora_apertura'] as String,
      horaCierre: json['hora_cierre'] as String,
      deporteId: deporte['id'] as int,
      deporte: deporte['nombre'] as String,
      sedeId: sede['id'] as int,
      sede: sede['nombre'] as String,
    );
  }

  bool get esIndoor => ambiente == 'Indoor';
}