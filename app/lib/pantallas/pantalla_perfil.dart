import 'package:flutter/material.dart';

import '../modelos/usuario.dart';
import '../navegacion.dart';
import '../servicios/api.dart';
import '../servicios/auth.dart';
import '../servicios/usuarios.dart';
import '../tema.dart';
import '../widgets/aviso_error.dart';
import '../widgets/campo_texto.dart';
import '../widgets/estado_error.dart';
import '../widgets/modal_error.dart';
import '../widgets/titulo_doble.dart';
import 'pantalla_cambiar_contrasena.dart';

// cu-05: ver y editar el perfil, modo oscuro, contraseña, cerrar sesion y eliminar cuenta
class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _dni = TextEditingController();
  final _fechaTexto = TextEditingController();
  final _email = TextEditingController();
  DateTime? _fechaNacimiento;

  // null mientras carga
  Usuario? _usuario;
  String? _error;
  bool _editando = false;
  bool _guardando = false;
  bool _eliminando = false;
  // problema al guardar, se muestra arriba de los campos
  String? _aviso;
  // para descartar respuestas viejas si se pide dos veces seguidas
  int _pedido = 0;

  @override
  void initState() {
    super.initState();
    // se recarga al entrar a la pestaña, salvo que se este editando
    pestanaActual.addListener(_alCambiarPestana);
    if (pestanaActual.value == 3) _cargar();
  }

  @override
  void dispose() {
    pestanaActual.removeListener(_alCambiarPestana);
    for (final c in [_nombre, _apellido, _dni, _fechaTexto, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  void _alCambiarPestana() {
    if (pestanaActual.value == 3 && !_editando) _cargar();
  }

  Future<void> _cargar() async {
    final pedido = ++_pedido;
    try {
      final usuario = await Usuarios.yo();
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _usuario = usuario;
        _error = null;
        _llenarCampos(usuario);
      });
    } on ErrorApi catch (e) {
      if (!mounted || pedido != _pedido) return;
      final mensaje = await manejarError(context, e);
      if (!mounted) return;
      setState(() => _error = mensaje ?? 'No se pudo cargar tu perfil.');
    }
  }

  void _reintentar() {
    setState(() => _error = null);
    _cargar();
  }

  String _dosDigitos(int n) => n.toString().padLeft(2, '0');

  String _fechaParaMostrar(DateTime f) => '${_dosDigitos(f.day)}/${_dosDigitos(f.month)}/${f.year}';

  void _llenarCampos(Usuario usuario) {
    _nombre.text = usuario.nombre;
    _apellido.text = usuario.apellido;
    _dni.text = usuario.dni;
    _email.text = usuario.email;
    _fechaNacimiento = usuario.fechaNacimiento;
    _fechaTexto.text = _fechaParaMostrar(usuario.fechaNacimiento);
  }

  void _empezarEdicion() => setState(() => _editando = true);

  // descarta los cambios y vuelve a los datos guardados
  void _cancelarEdicion() {
    FocusScope.of(context).unfocus();
    setState(() {
      _editando = false;
      _aviso = null;
      final usuario = _usuario;
      if (usuario != null) _llenarCampos(usuario);
    });
  }

  Future<void> _elegirFecha() async {
    FocusScope.of(context).unfocus();
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(hoy.year - 20),
      firstDate: DateTime(1900),
      lastDate: hoy,
      helpText: 'Fecha de nacimiento',
    );
    if (elegida == null) return;
    setState(() {
      _fechaNacimiento = elegida;
      _fechaTexto.text = _fechaParaMostrar(elegida);
    });
  }

  // revisa los datos antes de mandar nada, devuelve el problema o null si esta todo bien
  String? _validar() {
    final hayVacios = [_nombre, _apellido, _dni].any((c) => c.text.trim().isEmpty);
    if (hayVacios || _fechaNacimiento == null) return 'Completá todos los campos.';
    if (!RegExp(r'^\d{7,8}$').hasMatch(_dni.text.trim())) {
      return 'El DNI tiene que tener 7 u 8 números, sin puntos.';
    }
    return null;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final problema = _validar();
    if (problema != null) {
      setState(() => _aviso = problema);
      return;
    }

    setState(() {
      _guardando = true;
      _aviso = null;
    });
    try {
      final usuario = await Usuarios.editar(
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        dni: _dni.text.trim(),
        fechaNacimiento: _fechaNacimiento!,
      );
      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _editando = false;
        _llenarCampos(usuario);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos actualizados.')));
    } on ErrorApi catch (e) {
      if (!mounted) return;
      final mensaje = await manejarError(context, e);
      if (!mounted) return;
      // por ejemplo "Ya existe un usuario con ese DNI"
      if (mensaje != null) setState(() => _aviso = mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _cambiarContrasena() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PantallaCambiarContrasena()));
  }

  Future<void> _eliminarCuenta() async {
    final confirma = await _confirmarEliminacion();
    if (confirma != true || !mounted) return;

    setState(() => _eliminando = true);
    try {
      // si sale bien se cierra la sesion y la puerta muestra el login
      await Usuarios.eliminarCuenta();
    } on ErrorApi catch (e) {
      if (!mounted) return;
      final mensaje = await manejarError(context, e);
      if (!mounted) return;
      if (mensaje != null) {
        await mostrarError(context, titulo: 'No se pudo eliminar la cuenta', mensaje: mensaje);
      }
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }

  // modal de la zona de peligro, devuelve true si la contraseña fue confirmada
  Future<bool?> _confirmarEliminacion() {
    return showDialog<bool>(context: context, builder: (_) => const _ModalEliminarCuenta());
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;

    return Scaffold(
      body: SafeArea(
        // deslizar hacia abajo vuelve a pedir el perfil
        child: RefreshIndicator(
          onRefresh: () async {
            if (!_editando) await _cargar();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const TituloDoble('MI', 'PERFIL'),
              const SizedBox(height: 24),
              if (usuario != null) ...[
                _cabecera(usuario),
                const SizedBox(height: 20),
              ],
              _modoTema(),
              const SizedBox(height: 16),
              if (usuario != null)
                _datosPersonales()
              else if (_error != null)
                EstadoError(mensaje: _error!, alReintentar: _reintentar)
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 16),
              _botonSecundario(Icons.lock_reset, 'Cambiar contraseña', _cambiarContrasena),
              const SizedBox(height: 12),
              _botonSecundario(Icons.logout, 'Cerrar sesión', Auth.cerrarSesion),
              if (usuario != null) ...[
                const SizedBox(height: 24),
                _zonaDePeligro(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // cuadrado con iniciales, nombre, email y "miembro activo"
  Widget _cabecera(Usuario usuario) {
    final tema = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colores.lima, borderRadius: BorderRadius.circular(18)),
          child: Text(usuario.iniciales, style: estiloTitulo(26, Colores.negro)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario.nombreCompleto,
                style: estiloTitulo(22, tema.colorScheme.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                usuario.email,
                style: const TextStyle(color: Colores.gris, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'MIEMBRO ACTIVO',
                style: TextStyle(
                  color: tema.colorScheme.secondary,
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // como en el figma: muestra el modo actual con luna o sol
  Widget _modoTema() {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return _caja(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      child: Row(
        children: [
          Icon(oscuro ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 20, color: Colores.gris),
          const SizedBox(width: 12),
          Expanded(
            child: Text(oscuro ? 'Modo oscuro' : 'Modo claro', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: oscuro,
            onChanged: cambiarModoTema,
            activeTrackColor: Colores.lima,
            inactiveTrackColor: Colores.gris.withValues(alpha: 0.45),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            thumbColor: const WidgetStatePropertyAll(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _datosPersonales() {
    final tema = Theme.of(context);
    return _caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DATOS PERSONALES',
                  style: TextStyle(color: Colores.gris, fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w700),
                ),
              ),
              if (!_editando)
                OutlinedButton.icon(
                  onPressed: _empezarEdicion,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tema.colorScheme.secondary,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: _guardando ? null : _cancelarEdicion,
                  style: TextButton.styleFrom(foregroundColor: Colores.gris, visualDensity: VisualDensity.compact),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colores.negro),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.lima,
                    foregroundColor: Colores.negro,
                    disabledBackgroundColor: Colores.lima.withValues(alpha: 0.5),
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (_aviso != null) ...[
            AvisoError(mensaje: _aviso!),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: CampoTexto(etiqueta: 'Nombre', controlador: _nombre, habilitado: _editando)),
              const SizedBox(width: 12),
              Expanded(child: CampoTexto(etiqueta: 'Apellido', controlador: _apellido, habilitado: _editando)),
            ],
          ),
          const SizedBox(height: 16),
          CampoTexto(
            etiqueta: 'DNI',
            controlador: _dni,
            habilitado: _editando,
            teclado: TextInputType.number,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            etiqueta: 'Fecha de nacimiento',
            controlador: _fechaTexto,
            habilitado: _editando,
            soloLectura: true,
            alTocar: _elegirFecha,
            icono: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 16),
          // la consigna pide que el email no se pueda editar
          CampoTexto(
            etiqueta: 'Email (solo lectura)',
            controlador: _email,
            habilitado: false,
            icono: Icons.lock_outline,
          ),
        ],
      ),
    );
  }

  // boton de ancho completo con borde, como cerrar sesion en el figma
  Widget _botonSecundario(IconData icono, String texto, VoidCallback alTocar) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: alTocar,
        icon: Icon(icono, size: 18),
        label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: tema.colorScheme.secondary,
          backgroundColor: tema.colorScheme.surface,
          side: BorderSide(color: oscuro ? Colors.white10 : Colors.black12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _zonaDePeligro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colores.rojo.withValues(alpha: 0.08),
        border: Border.all(color: Colores.rojo.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colores.rojo, size: 16),
              SizedBox(width: 8),
              Text(
                'ZONA DE PELIGRO',
                style: TextStyle(color: Colores.rojo, fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _eliminando ? null : _eliminarCuenta,
              icon: _eliminando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.delete_outline, size: 18),
              label: const Text('Eliminar cuenta', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colores.rojo,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colores.rojo.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // caja con borde redondeado, como las tarjetas del figma
  Widget _caja({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: oscuro ? Colors.white10 : Colors.black12),
      ),
      child: child,
    );
  }
}

// modal de la zona de peligro: pide la contraseña antes de eliminar la cuenta.
// si la contraseña esta mal el modal no se cierra y muestra el error
class _ModalEliminarCuenta extends StatefulWidget {
  const _ModalEliminarCuenta();

  @override
  State<_ModalEliminarCuenta> createState() => _ModalEliminarCuentaState();
}

class _ModalEliminarCuentaState extends State<_ModalEliminarCuenta> {
  final _contrasena = TextEditingController();
  bool _verificando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // para habilitar el boton eliminar recien cuando se escribe algo
    _contrasena.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _verificando = true;
      _error = null;
    });
    try {
      await Auth.confirmarContrasena(_contrasena.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ErrorApi catch (e) {
      if (!mounted) return;
      setState(() {
        _verificando = false;
        _error = e.mensaje;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeEliminar = _contrasena.text.isNotEmpty && !_verificando;

    return AlertDialog(
      // para que no se tape con el teclado
      scrollable: true,
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colores.rojo, size: 18),
          SizedBox(width: 8),
          Text(
            'ZONA DE PELIGRO',
            style: TextStyle(color: Colores.rojo, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('¿Estás seguro? Esta acción elimina todos tus datos y tus reservas permanentemente.'),
          const SizedBox(height: 16),
          CampoTexto(
            etiqueta: 'Ingresá tu contraseña',
            controlador: _contrasena,
            esContrasena: true,
            habilitado: !_verificando,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _verificando ? null : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colores.gris,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: puedeEliminar ? _eliminar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colores.rojo,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colores.rojo.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _verificando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}