import 'package:flutter/material.dart';

import '../servicios/api.dart';
import '../servicios/auth.dart';
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

// para las pantallas con sesion iniciada:
// si la sesion vencio cierra sesion, si es de conexion muestra el modal
// devuelve el mensaje para mostrar en pantalla, o null si ya se encargo
Future<String?> manejarError(BuildContext context, ErrorApi e) async {
  if (e.codigo == 401) {
    await Auth.cerrarSesion();
    return null;
  }
  if (e.esDeConexion) {
    await mostrarError(context, titulo: e.titulo, mensaje: e.mensaje);
    return null;
  }
  return e.mensaje;
}