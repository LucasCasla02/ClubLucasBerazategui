import 'package:flutter/material.dart';

import '../imagenes.dart';
import '../modelos/sede.dart';
import '../tema.dart';
import 'deporte.dart';
import 'fondo_foto.dart';

// tarjeta de una sede con su foto, como en el figma
class TarjetaSede extends StatelessWidget {
  final Sede sede;
  final VoidCallback alTocar;

  const TarjetaSede({super.key, required this.sede, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estilo = estiloDeporte(sede.deportes.isNotEmpty ? sede.deportes.first : '');

    return Material(
      color: tema.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              child: FondoFoto(
                foto: fotoSede(sede.nombre),
                colorRespaldo: estilo.color,
                child: Stack(
                  children: [
                    Positioned(
                      left: 16,
                      right: 90,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('SEDE ${sede.nombre.toUpperCase()}', style: estiloTitulo(24, Colors.white)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  sede.direccion,
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // cantidad de canchas, abajo a la derecha
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text('${sede.cantidadEspacios}', style: estiloTitulo(20, Colores.lima)),
                            const Text('canchas', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final deporte in sede.deportes) ChipDeporte(deporte)],
                    ),
                  ),
                  Text(
                    'Ver canchas →',
                    style: TextStyle(color: tema.colorScheme.secondary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}