import 'package:flutter/material.dart';

import '../formato.dart';
import '../imagenes.dart';
import '../modelos/espacio.dart';
import '../tema.dart';
import 'deporte.dart';
import 'fondo_foto.dart';

// tarjeta de una cancha, como en el figma de cada sede
class TarjetaCancha extends StatelessWidget {
  final Espacio espacio;
  final VoidCallback alReservar;

  const TarjetaCancha({super.key, required this.espacio, required this.alReservar});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final estilo = estiloDeporte(espacio.deporte);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: oscuro ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            child: FondoFoto(
              foto: fotoCancha(espacio.deporte, espacio.variante),
              colorRespaldo: estilo.color,
              child: Stack(
                children: [
                  // tipo de cancha arriba a la izquierda
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _etiquetaOscura(
                      Text(
                        espacio.variante,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _etiquetaOscura(Icon(estilo.icono, size: 16, color: Colors.white)),
                  ),
                  // codigo de la cancha abajo
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Text(
                      espacio.nombre,
                      style: estiloCodigo(Colores.lima),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _dato(espacio.esIndoor ? Icons.home_outlined : Icons.wb_sunny_outlined, espacio.ambiente),
                          if (espacio.iluminada) _dato(Icons.lightbulb_outline, 'Iluminada'),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatoPrecio(espacio.precioPorHora),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const Text('/ hora', style: TextStyle(fontSize: 11, color: Colores.gris)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colores.gris),
                    const SizedBox(width: 4),
                    Text(
                      '${formatoHora(espacio.horaApertura)} a ${formatoHora(espacio.horaCierre)}',
                      style: const TextStyle(fontSize: 12, color: Colores.gris),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: alReservar,
                    icon: const Icon(Icons.bolt, size: 18),
                    label: Text('VER HORARIOS / RESERVAR', style: estiloTitulo(14, Colores.negro)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.lima,
                      foregroundColor: Colores.negro,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // etiqueta oscura y semitransparente para poner encima de la foto
  Widget _etiquetaOscura(Widget contenido) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
        ),
        child: contenido,
      );

  // dato chiquito gris, como indoor o iluminada
  Widget _dato(IconData icono, String texto) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colores.gris.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 12, color: Colores.gris),
            const SizedBox(width: 4),
            Text(texto, style: const TextStyle(fontSize: 12, color: Colores.gris)),
          ],
        ),
      );
}