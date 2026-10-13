import 'package:flutter/material.dart';

import '../formato.dart';
import '../imagenes.dart';
import '../modelos/espacio.dart';
import '../modelos/sede.dart';
import '../servicios/api.dart';
import '../servicios/catalogo.dart';
import '../tema.dart';
import '../widgets/chip_filtro.dart';
import '../widgets/deporte.dart';
import '../widgets/estado_error.dart';
import '../widgets/fondo_foto.dart';
import '../widgets/modal_error.dart';
import '../widgets/tarjeta_cancha.dart';

// detalle de una sede: filtros de deporte y de tipo, y sus canchas
class PantallaSede extends StatefulWidget {
  final Sede sede;

  const PantallaSede({super.key, required this.sede});

  @override
  State<PantallaSede> createState() => _PantallaSedeState();
}

class _PantallaSedeState extends State<PantallaSede> {
  // null mientras carga
  List<Espacio>? _espacios;
  String? _error;
  String? _deporte;
  // null es "todos"
  String? _variante;

  @override
  void initState() {
    super.initState();
    final deportes = widget.sede.deportes;
    _deporte = deportes.isNotEmpty ? deportes.first : null;
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final espacios = await Catalogo.espaciosDeSede(widget.sede.id);
      if (!mounted) return;
      setState(() {
        _espacios = espacios;
        _error = null;
      });
    } on ErrorApi catch (e) {
      if (!mounted) return;
      final mensaje = await manejarError(context, e);
      if (!mounted) return;
      setState(() => _error = mensaje ?? 'No se pudieron cargar las canchas.');
    }
  }

  void _reintentar() {
    setState(() => _error = null);
    _cargar();
  }

  // canchas del deporte elegido
  List<Espacio> get _delDeporte => (_espacios ?? []).where((e) => e.deporte == _deporte).toList();

  // tipos de cancha del deporte elegido, sin repetir
  List<String> get _variantes => _delDeporte.map((e) => e.variante).toSet().toList();

  List<Espacio> get _filtradas =>
      _variante == null ? _delDeporte : _delDeporte.where((e) => e.variante == _variante).toList();

  void _elegirDeporte(String deporte) {
    setState(() {
      _deporte = deporte;
      _variante = null;
    });
  }

  // se conecta en el paso 3.10
  void _reservar(Espacio espacio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('La reserva de ${espacio.variante} se arma en el paso 3.10')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtradas;
    final variantes = _variantes;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _encabezado(),
          const SizedBox(height: 16),
          // deportes de la sede
          _filaDeChips([
            for (final deporte in widget.sede.deportes)
              ChipFiltro(
                texto: deporte,
                icono: estiloDeporte(deporte).icono,
                elegido: deporte == _deporte,
                alTocar: () => _elegirDeporte(deporte),
              ),
          ]),
          // tipos de cancha, solo si el deporte tiene mas de uno
          if (variantes.length > 1) ...[
            const SizedBox(height: 10),
            _filaDeChips([
              ChipFiltro(
                texto: 'Todos',
                elegido: _variante == null,
                alTocar: () => setState(() => _variante = null),
              ),
              for (final variante in variantes)
                ChipFiltro(
                  texto: variante,
                  elegido: variante == _variante,
                  alTocar: () => setState(() => _variante = variante),
                ),
            ]),
          ],
          if (_espacios != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                '${filtradas.length} ${filtradas.length == 1 ? 'cancha' : 'canchas'} · $_deporte',
                style: const TextStyle(color: Colores.gris, fontSize: 12),
              ),
            ),
            for (final espacio in filtradas)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TarjetaCancha(espacio: espacio, alReservar: () => _reservar(espacio)),
              ),
          ] else if (_error != null)
            EstadoError(mensaje: _error!, alReintentar: _reintentar)
          else
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // fila de chips que se desliza de costado si no entran
  Widget _filaDeChips(List<Widget> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final chip in chips) Padding(padding: const EdgeInsets.only(right: 8), child: chip),
        ],
      ),
    );
  }

  // foto de la sede con el nombre, la direccion y el horario
  Widget _encabezado() {
    final sede = widget.sede;
    final arriba = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 220 + arriba,
      child: FondoFoto(
        foto: fotoSede(sede.nombre),
        colorRespaldo: estiloDeporte(_deporte ?? '').color,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, arriba + 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Todas las sedes'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SEDE',
                      style: TextStyle(color: Colores.lima, fontSize: 11, letterSpacing: 4, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('SEDE ${sede.nombre.toUpperCase()}', style: estiloTitulo(32, Colors.white)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(sede.direccion, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          'Abierta de ${formatoHora(sede.horaApertura)} a ${formatoHora(sede.horaCierre)}',
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
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