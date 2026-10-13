// formatos que se usan en varias pantallas

// 3800 -> $ 3.800
String formatoPrecio(num valor) {
  final texto = valor.round().toString();
  final conPuntos = texto.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  return '\$ $conPuntos';
}

// "08:00:00" -> "08:00"
String formatoHora(String hora) => hora.length >= 5 ? hora.substring(0, 5) : hora;