import 'package:flutter/material.dart';

import '../formato.dart';
import '../imagenes.dart';
import '../modelos/reserva.dart';
import '../tema.dart';
import 'deporte.dart';
import 'fondo_foto.dart';

// tarjeta de una reserva: sede, cancha, fecha, horario y total
// si alCancelar es null no se muestra el boton de cancelar
class TarjetaReserva extends StatelessWidget {
  final Reserva reserva;
  final VoidCallback? alCancelar;
  final bool cancelando;

  const TarjetaReserva({super.key, required this.reserva, this.alCancelar, this.cancelando = false});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final espacio = reserva.espacio;
    final estilo = estiloDeporte(espacio.deporte);
    final alCancelar = this.alCancelar;

    final tarjeta = Container(
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
            height: 100,
            child: FondoFoto(
              foto: fotoCancha(espacio.deporte, espacio.variante),
              colorRespaldo: estilo.color,
              child: Stack(
                children: [
                  Positioned(top: 10, left: 10, child: _etiquetaEstado()),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(estilo.icono, size: 16, color: Colors.white),
                    ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SEDE ${espacio.sede.toUpperCase()}',
                            style: estiloTitulo(18, tema.colorScheme.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${espacio.variante} · Cancha ${espacio.numero}',
                            style: const TextStyle(fontSize: 13, color: Colores.gris),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatoPrecio(reserva.montoTotal),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _dato(Icons.calendar_today_outlined, fechaCorta(reserva.fecha)),
                    const SizedBox(width: 8),
                    _dato(Icons.schedule, '${reserva.horaInicio} a ${reserva.horaFin}'),
                  ],
                ),
                if (alCancelar != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: cancelando ? null : alCancelar,
                      icon: cancelando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colores.rojo),
                            )
                          : const Icon(Icons.close, size: 18),
                      label: Text('CANCELAR RESERVA', style: estiloTitulo(14, Colores.rojo)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colores.rojo,
                        side: const BorderSide(color: Colores.rojo),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // las canceladas se ven apagadas
    return reserva.estaCancelada ? Opacity(opacity: 0.6, child: tarjeta) : tarjeta;
  }

  // activa en lima, completada en gris, cancelada en rojo
  Widget _etiquetaEstado() {
    final (texto, fondo, color) = switch (reserva.estadoActual) {
      'activa' => ('Activa', Colores.lima, Colores.negro),
      'cancelada' => ('Cancelada', Colores.rojo, Colors.white),
      _ => ('Completada', Colores.gris, Colors.white),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(8)),
      child: Text(texto, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  // dato chiquito gris, como la fecha o el horario
  Widget _dato(IconData icono, String texto) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colores.gris.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 13, color: Colores.gris),
            const SizedBox(width: 4),
            Text(texto, style: const TextStyle(fontSize: 12, color: Colores.gris, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}