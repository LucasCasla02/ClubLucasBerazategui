import 'package:flutter/material.dart';

import '../tema.dart';

// campo con la etiqueta arriba en mayuscula, como en el figma
class CampoTexto extends StatefulWidget {
  final String etiqueta;
  final String? pista;
  final TextEditingController controlador;
  final bool esContrasena;
  final bool habilitado;
  final TextInputType teclado;
  final String? Function(String?)? validador;
  // para campos que se tocan en vez de escribirse, como la fecha
  final bool soloLectura;
  final VoidCallback? alTocar;
  final IconData? icono;

  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.pista,
    this.esContrasena = false,
    this.habilitado = true,
    this.teclado = TextInputType.text,
    this.validador,
    this.soloLectura = false,
    this.alTocar,
    this.icono,
  });

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  // la contraseña arranca oculta
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final borde = oscuro ? Colors.white24 : Colors.black12;

    OutlineInputBorder linea(Color color, [double ancho = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: ancho),
        );

    Widget? iconoDerecha;
    if (widget.esContrasena) {
      iconoDerecha = IconButton(
        icon: Icon(_oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: () => setState(() => _oculto = !_oculto),
      );
    } else if (widget.icono != null) {
      iconoDerecha = Icon(widget.icono);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.etiqueta.toUpperCase(),
          style: const TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600, color: Colores.gris),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controlador,
          obscureText: widget.esContrasena && _oculto,
          enabled: widget.habilitado,
          keyboardType: widget.teclado,
          validator: widget.validador,
          readOnly: widget.soloLectura,
          onTap: widget.alTocar,
          decoration: InputDecoration(
            hintText: widget.pista,
            hintStyle: const TextStyle(color: Colores.gris),
            filled: true,
            fillColor: oscuro ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
            border: linea(borde),
            enabledBorder: linea(borde),
            disabledBorder: linea(borde),
            focusedBorder: linea(tema.colorScheme.secondary, 1.5),
            errorBorder: linea(Colores.rojo),
            focusedErrorBorder: linea(Colores.rojo, 1.5),
            suffixIcon: iconoDerecha,
          ),
        ),
      ],
    );
  }
}