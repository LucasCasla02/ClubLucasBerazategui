import 'package:flutter/material.dart';

import '../formato.dart';
import '../imagenes.dart';
import '../modelos/reserva.dart';
import '../modelos/sede.dart';
import '../modelos/usuario.dart';
import '../navegacion.dart';
import '../servicios/api.dart';
import '../servicios/catalogo.dart';
import '../servicios/reservas.dart';
import '../servicios/usuarios.dart';
import '../tema.dart';
import '../widgets/boton_principal.dart';
import '../widgets/chip_filtro.dart';
import '../widgets/deporte.dart';
import '../widgets/estado_error.dart';
import '../widgets/fondo_foto.dart';
import '../widgets/modal_error.dart';
import '../widgets/tarjeta_sede_chica.dart';
import 'pantalla_sede.dart';

// home: saludo, proxima reserva, filtro por deporte y sedes
class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  // null mientras carga
  Usuario? _usuario;
  List<Reserva>? _proximas;
  List<Sede>? _sedes;
  String? _error;
  // null es "Todos"
  String? _deporte;
  // para descartar respuestas viejas si se pide dos veces seguidas
  int _pedido = 0;

  @override
  void initState() {
    super.initState();
    // se recarga cada vez que se vuelve a inicio (la proxima reserva puede cambiar)
    pestanaActual.addListener(_alCambiarPestana);
    if (pestanaActual.value == 0) _cargar();
  }

  @override
  void dispose() {
    pestanaActual.removeListener(_alCambiarPestana);
    super.dispose();
  }

  void _alCambiarPestana() {
    if (pestanaActual.value == 0) _cargar();
  }

  Future<void> _cargar() async {
    final pedido = ++_pedido;
    try {
      // los tres pedidos salen juntos
      final datos = await Future.wait<Object>([Usuarios.yo(), Reservas.proximas(), Catalogo.sedes()]);
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _usuario = datos[0] as Usuario;
        _proximas = datos[1] as List<Reserva>;
        _sedes = datos[2] as List<Sede>;
        _error = null;
      });
    } on ErrorApi catch (e) {
      if (!mounted || pedido != _pedido) return;
      final mensaje = await manejarError(context, e);
      if (!mounted) return;
      setState(() => _error = mensaje ?? 'No se pudo cargar el inicio.');
    }
  }

  void _reintentar() {
    setState(() => _error = null);
    _cargar();
  }

  void _abrirSede(Sede sede) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PantallaSede(sede: sede)));
  }

  @override
  Widget build(BuildContext context) {
    final proximas = _proximas;
    final sedes = _sedes;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        // deslizar hacia abajo vuelve a pedir todo
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _cabecera(),
              if (proximas != null && sedes != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: proximas.isEmpty ? _sinReserva() : _proximaReserva(proximas.first),
                ),
                const SizedBox(height: 20),
                _filtroDeportes(sedes),
                const SizedBox(height: 24),
                _sedesDisponibles(sedes),
              ] else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: EstadoError(mensaje: _error!, alReintentar: _reintentar),
                )
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

  // foto de cancha con el saludo, el avatar y "zona deportiva"
  Widget _cabecera() {
    final usuario = _usuario;
    return SizedBox(
      height: 240,
      child: FondoFoto(
        foto: fotoDeporte('Fútbol'),
        colorRespaldo: Colores.limaOscuro,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _saludo(),
                          style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          usuario?.nombreCompleto ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (usuario != null)
                    // el avatar lleva a perfil
                    GestureDetector(
                      onTap: () => pestanaActual.value = 3,
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Colores.lima, shape: BoxShape.circle),
                        child: Text(
                          usuario.iniciales,
                          style: const TextStyle(color: Colores.negro, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              const Text(
                'CLUB LUCAS BERAZATEGUI',
                style: TextStyle(color: Colores.lima, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('ZONA DEPORTIVA', style: estiloTitulo(36, Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  String _saludo() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'BUENOS DÍAS,';
    if (hora >= 12 && hora < 20) return 'BUENAS TARDES,';
    return 'BUENAS NOCHES,';
  }

  // "hoy", "mañana" o "en 3 días"
  String _cuando(DateTime fecha) {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final dias = (DateUtils.dateOnly(fecha).difference(hoy).inHours / 24).round();
    if (dias <= 0) return 'hoy';
    if (dias == 1) return 'mañana';
    return 'en $dias días';
  }

  // la reserva mas cercana, al tocarla lleva a mis reservas
  Widget _proximaReserva(Reserva reserva) {
    final tema = Theme.of(context);
    final acento = tema.colorScheme.secondary;
    final espacio = reserva.espacio;

    return _tarjeta(
      alTocar: () => pestanaActual.value = 2,
      child: Column(
        children: [
          Row(
            children: [
              _etiqueta('PRÓXIMA RESERVA', acento),
              const Spacer(),
              Text(_cuando(reserva.fecha), style: const TextStyle(color: Colores.gris, fontSize: 12)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 14, color: Colores.gris),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: FondoFoto(
                    foto: fotoCancha(espacio.deporte, espacio.variante),
                    colorRespaldo: estiloDeporte(espacio.deporte).color,
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sede ${espacio.sede}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(espacio.nombre, style: estiloCodigo(Colores.gris), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    reserva.horaInicio,
                    style: TextStyle(color: acento, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(reserva.horaFin, style: const TextStyle(color: Colores.gris, fontSize: 12)),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Text(fechaCorta(reserva.fecha), style: const TextStyle(color: Colores.gris, fontSize: 13)),
              const Spacer(),
              Text(
                formatoPrecio(reserva.montoTotal),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // cuando no hay reservas proximas
  Widget _sinReserva() {
    return _tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _etiqueta('PRÓXIMA RESERVA', Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 12),
          const Text('No tenés reservas próximas.', style: TextStyle(color: Colores.gris)),
          const SizedBox(height: 16),
          BotonPrincipal(texto: 'Reservar cancha', alTocar: () => pestanaActual.value = 1),
        ],
      ),
    );
  }

  // chips Todos + los deportes de todas las sedes, filtran las sedes de abajo
  Widget _filtroDeportes(List<Sede> sedes) {
    final deportes = <String>[];
    for (final sede in sedes) {
      for (final deporte in sede.deportes) {
        if (!deportes.contains(deporte)) deportes.add(deporte);
      }
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          ChipFiltro(texto: 'Todos', elegido: _deporte == null, alTocar: () => setState(() => _deporte = null)),
          for (final deporte in deportes) ...[
            const SizedBox(width: 8),
            ChipFiltro(
              texto: deporte,
              icono: estiloDeporte(deporte).icono,
              elegido: _deporte == deporte,
              alTocar: () => setState(() => _deporte = deporte),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sedesDisponibles(List<Sede> sedes) {
    final filtradas = _deporte == null ? sedes : sedes.where((s) => s.deportes.contains(_deporte)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text('SEDES DISPONIBLES', style: estiloTitulo(20, Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              TextButton(onPressed: () => pestanaActual.value = 1, child: const Text('Ver todas →')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (filtradas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Ninguna sede tiene ese deporte.', style: TextStyle(color: Colores.gris)),
          )
        else
          // lista que se desliza de costado
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: filtradas.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => TarjetaSedeChica(sede: filtradas[i], alTocar: () => _abrirSede(filtradas[i])),
            ),
          ),
      ],
    );
  }

  // caja con borde redondeado, como las tarjetas del figma
  Widget _tarjeta({required Widget child, VoidCallback? alTocar}) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    return Material(
      color: tema.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: oscuro ? Colors.white10 : Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  Widget _etiqueta(String texto, Color color) => Text(
        texto,
        style: TextStyle(color: color, fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w800),
      );
}