import 'package:flutter/material.dart';

import '../tema.dart';

// modal de error con boton aceptar, como en el figma
Future<void> mostrarError(BuildContext context, {required String titulo, required String mensaje}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        titulo.toUpperCase(),
        style: const TextStyle(color: Colores.rojo, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700),
      ),
      content: Text(mensaje),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Aceptar')),
        ),
      ],
    ),
  );
}