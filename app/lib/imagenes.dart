// fotos que vienen dentro de la app, en assets/imagenes

String? fotoSede(String nombre) {
  switch (nombre) {
    case 'Morón':
      return 'assets/imagenes/sedes/moron.jpg';
    case 'Ramos Mejía':
      return 'assets/imagenes/sedes/ramos_mejia.jpg';
    case 'San Justo':
      return 'assets/imagenes/sedes/san_justo.jpg';
    case 'Castelar':
      return 'assets/imagenes/sedes/castelar.jpg';
    default:
      return null;
  }
}

String? fotoDeporte(String deporte) {
  switch (deporte) {
    case 'Fútbol':
      return 'assets/imagenes/canchas/futbol.jpg';
    case 'Tenis':
      return 'assets/imagenes/canchas/tenis.jpg';
    case 'Hockey':
      return 'assets/imagenes/canchas/hockey.jpg';
    case 'Vóley':
      return 'assets/imagenes/canchas/voley.jpg';
    case 'Golf':
      return 'assets/imagenes/canchas/golf.jpg';
    default:
      return null;
  }
}