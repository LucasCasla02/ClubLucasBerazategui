import 'package:flutter/material.dart';

import '../tema.dart';

// chip que se puede elegir, el elegido se pinta de lima como en el figma
class ChipFiltro extends StatelessWidget {
  final String texto;
  final bool elegido;
  final VoidCallback alTocar;
  final IconData? icono;

  const ChipFiltro({
    super.key,
    required this.texto,
    required this.elegido,
    required this.alTocar,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final colorTexto = elegido ? Colores.negro : tema.colorScheme.onSurface;
    final borde = elegido ? Colores.lima : (oscuro ? Colors.white24 : Colors.black12);

    return Material(
      color: elegido ? Colores.lima : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: borde)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icono != null) ...[
                Icon(icono, size: 16, color: colorTexto),
                const SizedBox(width: 6),
              ],
              Text(texto, style: TextStyle(color: colorTexto, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}