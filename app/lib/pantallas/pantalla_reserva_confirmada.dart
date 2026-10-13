import 'dart:async';

import 'package:flutter/material.dart';

import '../navegacion.dart';
import '../tema.dart';

// "reserva confirmada", a los 2 segundos (o al tocar) va a mis reservas
class PantallaReservaConfirmada extends StatefulWidget {
  const PantallaReservaConfirmada({super.key});

  @override
  State<PantallaReservaConfirmada> createState() => _PantallaReservaConfirmadaState();
}

class _PantallaReservaConfirmadaState extends State<PantallaReservaConfirmada> {
  Timer? _espera;

  @override
  void initState() {
    super.initState();
    _espera = Timer(const Duration(seconds: 2), _irAReservas);
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  void _irAReservas() {
    _espera?.cancel();
    if (!mounted) return;
    pestanaActual.value = 2;
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.negro,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _irAReservas,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: Colores.lima, borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.check_rounded, size: 56, color: Colores.negro),
              ),
              const SizedBox(height: 32),
              Text('¡RESERVA', style: estiloTitulo(40, Colors.white)),
              Text('CONFIRMADA!', style: estiloTitulo(48, Colores.lima)),
              const SizedBox(height: 16),
              const Text('Redirigiendo a tus reservas...', style: TextStyle(color: Colores.gris)),
            ],
          ),
        ),
      ),
    );
  }
}