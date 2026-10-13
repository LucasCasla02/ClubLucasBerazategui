import 'package:flutter/material.dart';

import '../imagenes.dart';
import '../modelos/sede.dart';
import '../tema.dart';
import 'deporte.dart';
import 'fondo_foto.dart';

// tarjeta angosta de una sede para la lista que se desliza en inicio
class TarjetaSedeChica extends StatelessWidget {
  final Sede sede;
  final VoidCallback alTocar;

  const TarjetaSedeChica({super.key, required this.sede, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final estilo = estiloDeporte(sede.deportes.isNotEmpty ? sede.deportes.first : '');
    // entran 2 chips en una linea, el resto se resume en +N
    final visibles = sede.deportes.take(2).toList();
    final restantes = sede.deportes.length - visibles.length;

    return SizedBox(
      width: 250,
      child: Material(
        color: tema.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: oscuro ? Colors.white10 : Colors.black12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                child: FondoFoto(
                  foto: fotoSede(sede.nombre),
                  colorRespaldo: estilo.color,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(sede.nombre.toUpperCase(), style: estiloTitulo(18, Colors.white)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colores.gris),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sede.direccion,
                            style: const TextStyle(fontSize: 12, color: Colores.gris),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final deporte in visibles) ...[
                          ChipDeporte(deporte),
                          const SizedBox(width: 6),
                        ],
                        if (restantes > 0)
                          Text(
                            '+$restantes',
                            style: const TextStyle(fontSize: 12, color: Colores.gris, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}