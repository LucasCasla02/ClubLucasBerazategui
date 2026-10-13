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

// primero busca una foto del tipo de cancha, si no hay usa la del deporte
String? fotoCancha(String deporte, String variante) {
  switch (variante) {
    case 'Fútbol 7':
    case 'Fútbol 8':
      return 'assets/imagenes/canchas/futbol_7.jpg';
    case 'Fútbol 11':
      return 'assets/imagenes/canchas/futbol_11.jpg';
    case 'Cemento':
      return 'assets/imagenes/canchas/tenis_cemento.jpg';
    case 'Sintético':
      return 'assets/imagenes/canchas/tenis_sintetico.jpg';
    case 'Vóley Playa':
      return 'assets/imagenes/canchas/voley_playa.jpg';
    case '9 Hoyos':
      return 'assets/imagenes/canchas/golf_9hoyos.jpg';
    default:
      return fotoDeporte(deporte);
  }
}