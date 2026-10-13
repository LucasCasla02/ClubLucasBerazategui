// formatos que se usan en varias pantallas

const _dias = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

String _dosDigitos(int n) => n.toString().padLeft(2, '0');

// 3800 -> $ 3.800
String formatoPrecio(num valor) {
  final texto = valor.round().toString();
  final conPuntos = texto.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  return '\$ $conPuntos';
}

// "08:00:00" -> "08:00"
String formatoHora(String hora) => hora.length >= 5 ? hora.substring(0, 5) : hora;

// fecha como la espera la api: 2026-10-14
String fechaIso(DateTime fecha) => '${fecha.year}-${_dosDigitos(fecha.month)}-${_dosDigitos(fecha.day)}';

// dia de la semana corto: MIÉ
String diaCorto(DateTime fecha) => _dias[fecha.weekday - 1];

// fecha para mostrar: mié 14/10
String fechaCorta(DateTime fecha) =>
    '${diaCorto(fecha).toLowerCase()} ${_dosDigitos(fecha.day)}/${_dosDigitos(fecha.month)}';