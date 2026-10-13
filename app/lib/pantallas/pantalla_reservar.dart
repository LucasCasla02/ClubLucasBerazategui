import 'package:flutter/material.dart';

import '../formato.dart';
import '../imagenes.dart';
import '../modelos/espacio.dart';
import '../modelos/franja.dart';
import '../modelos/sede.dart';
import '../servicios/api.dart';
import '../servicios/catalogo.dart';
import '../servicios/reservas.dart';
import '../tema.dart';
import '../widgets/boton_principal.dart';
import '../widgets/chip_filtro.dart';
import '../widgets/deporte.dart';
import '../widgets/estado_error.dart';
import '../widgets/fondo_foto.dart';
import '../widgets/modal_error.dart';
import 'pantalla_reserva_confirmada.dart';

// elegir cancha, fecha, duracion y horario, y confirmar la reserva
class PantallaReservar extends StatefulWidget {
  final Sede sede;
  // canchas del mismo tipo en esa sede, para poder cambiar entre ellas
  final List<Espacio> canchas;
  final Espacio inicial;

  const PantallaReservar({super.key, required this.sede, required this.canchas, required this.inicial});

  @override
  State<PantallaReservar> createState() => _PantallaReservarState();
}

class _PantallaReservarState extends State<PantallaReservar> {
  static const _diasAMostrar = 7;

  late Espacio _cancha = widget.inicial;
  late final List<DateTime> _dias;
  late DateTime _fecha;
  int _duracion = 1;
  // null mientras carga
  List<Franja>? _franjas;
  String? _error;
  Franja? _elegida;
  bool _confirmando = false;

  @override
  void initState() {
    super.initState();
    final hoy = DateUtils.dateOnly(DateTime.now());
    _dias = [for (var i = 0; i < _diasAMostrar; i++) hoy.add(Duration(days: i))];
    _fecha = _dias.first;
    _cargarHorarios();
  }

  // pide los horarios de la cancha, fecha y duracion elegidas
  Future<void> _cargarHorarios() async {
    final cancha = _cancha;
    final fecha = _fecha;
    final duracion = _duracion;
    try {
      final franjas = await Catalogo.horarios(cancha.id, fecha, duracion);
      // si mientras tanto se cambio algo, esta respuesta ya no sirve
      if (!mounted || cancha != _cancha || fecha != _fecha || duracion != _duracion) return;
      setState(() {
        _franjas = franjas;
        _error = null;
      });
    } on ErrorApi catch (e) {
      if (!mounted) return;
      final mensaje = await manejarError(context, e);
      if (!mounted) return;
      setState(() => _error = mensaje ?? 'No se pudieron cargar los horarios.');
    }
  }

  // al cambiar cancha, fecha o duracion se vuelven a pedir los horarios
  void _cambiar(VoidCallback cambio) {
    setState(() {
      cambio();
      _franjas = null;
      _error = null;
      _elegida = null;
    });
    _cargarHorarios();
  }

  Future<void> _confirmar() async {
    final franja = _elegida;
    if (franja == null) return;
    setState(() => _confirmando = true);
    try {
      await Reservas.crear(
        espacioId: _cancha.id,
        fecha: _fecha,
        horaInicio: franja.horaInicio,
        horaFin: franja.horaFin,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PantallaReservaConfirmada()),
      );
    } on ErrorApi catch (e) {
      if (!mounted) return;
      final mensaje = await manejarError(context, e);
      if (!mounted) return;
      if (mensaje != null) {
        await mostrarError(context, titulo: 'No se pudo reservar', mensaje: mensaje);
        if (!mounted) return;
      }
      // el horario pudo haberse ocupado, se vuelven a pedir
      _cambiar(() {});
    } finally {
      if (mounted) setState(() => _confirmando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final franjas = _franjas;
    final noDisponibles = franjas?.where((f) => !f.disponible).length ?? 0;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _encabezado(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.canchas.length > 1) ...[
                  _titulo('Seleccioná cancha'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cancha in widget.canchas)
                        ChipFiltro(
                          texto: 'Cancha ${cancha.numero} · ${cancha.ambiente}',
                          elegido: cancha.id == _cancha.id,
                          alTocar: () => _cambiar(() => _cancha = cancha),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                _titulo('Fecha'),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dias.length,
                    separatorBuilder: (context, indice) => const SizedBox(width: 8),
                    itemBuilder: (context, indice) => _dia(_dias[indice]),
                  ),
                ),
                const SizedBox(height: 20),
                _titulo('Duración'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1 hora')),
                      ButtonSegment(value: 2, label: Text('2 horas')),
                    ],
                    selected: {_duracion},
                    showSelectedIcon: false,
                    onSelectionChanged: (elegidos) => _cambiar(() => _duracion = elegidos.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: Colores.lima,
                      selectedForegroundColor: Colores.negro,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _titulo('Horario disponible'),
                if (franjas != null) ...[
                  if (franjas.isEmpty)
                    const Text('No hay horarios para este día.', style: TextStyle(color: Colores.gris))
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 3.4,
                      children: [for (final franja in franjas) _horario(franja)],
                    ),
                  if (noDisponibles > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$noDisponibles horarios no disponibles',
                        style: const TextStyle(color: Colores.gris, fontSize: 12),
                      ),
                    ),
                ] else if (_error != null)
                  EstadoError(mensaje: _error!, alReintentar: () => _cambiar(() {}))
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                const SizedBox(height: 20),
                if (_elegida != null) ...[
                  _resumen(tema),
                  const SizedBox(height: 16),
                ],
                BotonPrincipal(
                  texto: _elegida == null ? 'Seleccioná un horario' : 'Confirmar reserva',
                  alTocar: _elegida == null ? null : _confirmar,
                  cargando: _confirmando,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600, color: Colores.gris),
      ),
    );
  }

  // foto de la sede con el deporte y el nombre
  Widget _encabezado() {
    final arriba = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 170 + arriba,
      child: FondoFoto(
        foto: fotoSede(widget.sede.nombre),
        colorRespaldo: estiloDeporte(_cancha.deporte).color,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, arriba + 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Volver'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_cancha.deporte.toUpperCase()} · ${_cancha.variante.toUpperCase()}',
                      style: const TextStyle(color: Colores.lima, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('SEDE ${widget.sede.nombre.toUpperCase()}', style: estiloTitulo(30, Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // un dia de la tira de fechas
  Widget _dia(DateTime dia) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final elegido = dia == _fecha;
    final colorTexto = elegido ? Colores.negro : tema.colorScheme.onSurface;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: elegido ? Colores.lima : (oscuro ? Colors.white24 : Colors.black12)),
    );

    return Material(
      color: elegido ? Colores.lima : Colors.transparent,
      shape: forma,
      child: InkWell(
        customBorder: forma,
        onTap: () => _cambiar(() => _fecha = dia),
        child: SizedBox(
          width: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(diaCorto(dia), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colorTexto)),
              const SizedBox(height: 2),
              Text('${dia.day}', style: estiloTitulo(22, colorTexto)),
            ],
          ),
        ),
      ),
    );
  }

  // un horario de la grilla: libre, elegido o tachado si no esta disponible
  Widget _horario(Franja franja) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final elegida = identical(_elegida, franja);
    final libre = franja.disponible;
    final colorTexto = elegida
        ? Colores.negro
        : (libre ? tema.colorScheme.onSurface : Colores.gris.withValues(alpha: 0.6));
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: elegida ? Colores.lima : (oscuro ? Colors.white24 : Colors.black12)),
    );

    return Material(
      color: elegida
          ? Colores.lima
          : (libre ? Colors.transparent : Colores.gris.withValues(alpha: 0.12)),
      shape: forma,
      child: InkWell(
        customBorder: forma,
        onTap: libre ? () => setState(() => _elegida = franja) : null,
        child: Center(
          child: Text(
            '${franja.horaInicio} - ${franja.horaFin}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorTexto,
              decoration: libre ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }

  // resumen con el total, como en el figma
  Widget _resumen(ThemeData tema) {
    final franja = _elegida!;
    final total = _cancha.precioPorHora * _duracion;
    final oscuro = tema.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: oscuro ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_cancha.variante, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      '${_cancha.deporte} · Cancha ${_cancha.numero} · ${_duracion}h',
                      style: const TextStyle(fontSize: 12, color: Colores.gris),
                    ),
                  ],
                ),
              ),
              Text('${formatoPrecio(_cancha.precioPorHora)} × $_duracion', style: estiloCodigo(Colores.gris)),
            ],
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 12, color: Colores.gris)),
                    Text(formatoPrecio(total), style: estiloTitulo(32, tema.colorScheme.onSurface)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${franja.horaInicio} - ${franja.horaFin}', style: estiloTitulo(18, tema.colorScheme.secondary)),
                  Text(fechaCorta(_fecha), style: const TextStyle(fontSize: 12, color: Colores.gris)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}