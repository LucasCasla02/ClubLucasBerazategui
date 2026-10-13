import 'package:flutter/material.dart';

import '../formato.dart';
import '../modelos/reserva.dart';
import '../navegacion.dart';
import '../servicios/api.dart';
import '../servicios/reservas.dart';
import '../tema.dart';
import '../widgets/boton_principal.dart';
import '../widgets/estado_error.dart';
import '../widgets/modal_error.dart';
import '../widgets/tarjeta_reserva.dart';
import '../widgets/titulo_doble.dart';

// mis reservas: proximas (se pueden cancelar) e historial completo
class PantallaReservas extends StatefulWidget {
  const PantallaReservas({super.key});

  @override
  State<PantallaReservas> createState() => _PantallaReservasState();
}

class _PantallaReservasState extends State<PantallaReservas> {
  bool _verHistorial = false;
  // null mientras carga
  List<Reserva>? _proximas;
  List<Reserva>? _historial;
  String? _error;
  int? _cancelandoId;
  // para descartar respuestas viejas si se pide dos veces seguidas
  int _pedido = 0;

  @override
  void initState() {
    super.initState();
    // la pestaña queda viva en el indexedstack, asi que se recarga cada vez que se entra
    pestanaActual.addListener(_alCambiarPestana);
    if (pestanaActual.value == 2) _cargar();
  }

  @override
  void dispose() {
    pestanaActual.removeListener(_alCambiarPestana);
    super.dispose();
  }

  void _alCambiarPestana() {
    if (pestanaActual.value == 2) _cargar();
  }

  Future<void> _cargar() async {
    final pedido = ++_pedido;
    try {
      final listas = await Future.wait([Reservas.proximas(), Reservas.historial()]);
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _proximas = listas[0];
        _historial = listas[1];
        _error = null;
      });
    } on ErrorApi catch (e) {
      if (!mounted || pedido != _pedido) return;
      final mensaje = await manejarError(context, e);
      if (!mounted) return;
      setState(() => _error = mensaje ?? 'No se pudieron cargar tus reservas.');
    }
  }

  void _reintentar() {
    setState(() => _error = null);
    _cargar();
  }

  Future<void> _cancelar(Reserva reserva) async {
    final confirma = await _confirmarCancelacion(reserva);
    if (confirma != true || !mounted) return;

    setState(() => _cancelandoId = reserva.id);
    try {
      await Reservas.cancelar(reserva.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva cancelada. El horario quedó libre.')),
      );
    } on ErrorApi catch (e) {
      if (!mounted) return;
      final mensaje = await manejarError(context, e);
      if (!mounted) return;
      if (mensaje != null) {
        await mostrarError(context, titulo: 'No se pudo cancelar', mensaje: mensaje);
      }
    } finally {
      if (mounted) setState(() => _cancelandoId = null);
    }
    // haya salido bien o mal, se vuelve a pedir la lista
    if (mounted) await _cargar();
  }

  // modal por si se toco cancelar sin querer
  Future<bool?> _confirmarCancelacion(Reserva reserva) {
    final espacio = reserva.espacio;
    return showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text(
          'CANCELAR RESERVA',
          style: TextStyle(color: Colores.rojo, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés cancelar esta reserva?\n\n'
          'Sede ${espacio.sede} · ${espacio.variante} · Cancha ${espacio.numero}\n'
          '${fechaCorta(reserva.fecha)} de ${reserva.horaInicio} a ${reserva.horaFin}\n\n'
          'El horario va a quedar libre para otros.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Volver')),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colores.rojo),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proximas = _proximas;

    return Scaffold(
      body: SafeArea(
        // deslizar hacia abajo vuelve a pedir las reservas
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            // para que se pueda deslizar aunque la lista sea corta
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const TituloDoble('MIS', 'RESERVAS'),
              const SizedBox(height: 4),
              if (proximas != null)
                Text(
                  proximas.length == 1 ? '1 reserva próxima' : '${proximas.length} reservas próximas',
                  style: const TextStyle(color: Colores.gris),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Próximas')),
                    ButtonSegment(value: true, label: Text('Historial')),
                  ],
                  selected: {_verHistorial},
                  showSelectedIcon: false,
                  onSelectionChanged: (elegidos) => setState(() => _verHistorial = elegidos.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Colores.lima,
                    selectedForegroundColor: Colores.negro,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ..._contenido(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _contenido() {
    final lista = _verHistorial ? _historial : _proximas;

    if (lista == null) {
      if (_error != null) return [EstadoError(mensaje: _error!, alReintentar: _reintentar)];
      return const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (lista.isEmpty) return [_vacio()];

    return [
      for (final reserva in lista)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TarjetaReserva(
            reserva: reserva,
            // solo las proximas se pueden cancelar
            alCancelar: _verHistorial ? null : () => _cancelar(reserva),
            cancelando: _cancelandoId == reserva.id,
          ),
        ),
    ];
  }

  Widget _vacio() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Icon(Icons.event_busy_outlined, size: 48, color: Colores.gris),
          const SizedBox(height: 12),
          Text(
            _verHistorial ? 'Todavía no hiciste ninguna reserva.' : 'No tenés reservas próximas.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colores.gris),
          ),
          if (!_verHistorial) ...[
            const SizedBox(height: 20),
            // lleva a la pestaña de sedes
            BotonPrincipal(texto: 'Reservar cancha', alTocar: () => pestanaActual.value = 1),
          ],
        ],
      ),
    );
  }
}