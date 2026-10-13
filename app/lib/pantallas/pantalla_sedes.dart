import 'package:flutter/material.dart';

import '../modelos/sede.dart';
import '../servicios/api.dart';
import '../servicios/catalogo.dart';
import '../tema.dart';
import '../widgets/estado_error.dart';
import '../widgets/modal_error.dart';
import '../widgets/tarjeta_sede.dart';
import '../widgets/titulo_doble.dart';

class PantallaSedes extends StatefulWidget {
  const PantallaSedes({super.key});

  @override
  State<PantallaSedes> createState() => _PantallaSedesState();
}

class _PantallaSedesState extends State<PantallaSedes> {
  // null mientras carga
  List<Sede>? _sedes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final sedes = await Catalogo.sedes();
      if (!mounted) return;
      setState(() {
        _sedes = sedes;
        _error = null;
      });
    } on ErrorApi catch (e) {
      if (!mounted) return;
      final mensaje = await manejarError(context, e);
      if (!mounted) return;
      setState(() => _error = mensaje ?? 'No se pudieron cargar las sedes.');
    }
  }

  void _reintentar() {
    setState(() => _error = null);
    _cargar();
  }

  // se conecta en la parte b
  void _abrir(Sede sede) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('El detalle de ${sede.nombre} se arma en la parte B')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sedes = _sedes;
    final totalCanchas = sedes?.fold<int>(0, (suma, s) => suma + s.cantidadEspacios) ?? 0;

    return Scaffold(
      body: SafeArea(
        // deslizar hacia abajo vuelve a pedir las sedes
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const TituloDoble('TODAS LAS', 'SEDES'),
              const SizedBox(height: 4),
              if (sedes != null)
                Text(
                  '${sedes.length} sedes · $totalCanchas canchas disponibles',
                  style: const TextStyle(color: Colores.gris),
                ),
              const SizedBox(height: 20),
              if (sedes != null)
                for (final sede in sedes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TarjetaSede(sede: sede, alTocar: () => _abrir(sede)),
                  )
              else if (_error != null)
                EstadoError(mensaje: _error!, alReintentar: _reintentar)
              else
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}