import 'package:flutter/material.dart';

import '../servicios/api.dart';
import '../servicios/auth.dart';
import '../tema.dart';
import '../widgets/aviso_error.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto.dart';
import '../widgets/modal_error.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _dni = TextEditingController();
  final _fechaTexto = TextEditingController();
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  final _scroll = ScrollController();
  DateTime? _fechaNacimiento;
  bool _cargando = false;
  String? _aviso;

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _dni, _fechaTexto, _email, _contrasena]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  String _dosDigitos(int n) => n.toString().padLeft(2, '0');

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
      _fechaTexto.text = '${_dosDigitos(elegida.day)}/${_dosDigitos(elegida.month)}/${elegida.year}';
    });
  }

  // revisa los datos antes de mandar nada, devuelve el problema o null si esta todo bien
  String? _validar() {
    final hayVacios = [_nombre, _apellido, _dni, _email, _contrasena].any((c) => c.text.trim().isEmpty);
    if (hayVacios || _fechaNacimiento == null) return 'Completá todos los campos.';
    if (!RegExp(r'^\d{7,8}$').hasMatch(_dni.text.trim())) {
      return 'El DNI tiene que tener 7 u 8 números, sin puntos.';
    }
    if (!_email.text.contains('@')) return 'El email no tiene un formato válido.';
    if (_contrasena.text.length < 8) return 'La contraseña tiene que tener al menos 8 caracteres.';
    return null;
  }

  // muestra el cartel y sube para que se vea
  void _mostrarAviso(String mensaje) {
    setState(() => _aviso = mensaje);
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _crearCuenta() async {
    FocusScope.of(context).unfocus();
    final problema = _validar();
    if (problema != null) {
      _mostrarAviso(problema);
      return;
    }

    final fecha = _fechaNacimiento!;
    setState(() {
      _cargando = true;
      _aviso = null;
    });
    try {
      await Auth.registrar(
        email: _email.text,
        contrasena: _contrasena.text,
        perfil: {
          'nombre': _nombre.text.trim(),
          'apellido': _apellido.text.trim(),
          'dni': _dni.text.trim(),
          'fecha_nacimiento': '${fecha.year}-${_dosDigitos(fecha.month)}-${_dosDigitos(fecha.day)}',
        },
      );
      if (!mounted) return;
      // vuelve a la puerta, que ya muestra el inicio
      Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } on ErrorApi catch (e) {
      if (!mounted) return;
      if (e.esDeConexion) {
        await mostrarError(context, titulo: e.titulo, mensaje: e.mensaje);
      } else {
        _mostrarAviso(e.mensaje);
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Volver'),
                style: TextButton.styleFrom(foregroundColor: Colores.gris, padding: EdgeInsets.zero),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'NUEVA CUENTA',
              style: TextStyle(color: tema.colorScheme.secondary, fontSize: 11, letterSpacing: 4, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'CREAR ', style: estiloTitulo(40, tema.colorScheme.onSurface)),
                  TextSpan(text: 'CUENTA', style: estiloTitulo(40, tema.colorScheme.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_aviso != null) ...[
              AvisoError(mensaje: _aviso!),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: CampoTexto(etiqueta: 'Nombre', pista: 'Juan', controlador: _nombre)),
                const SizedBox(width: 12),
                Expanded(child: CampoTexto(etiqueta: 'Apellido', pista: 'Pérez', controlador: _apellido)),
              ],
            ),
            const SizedBox(height: 16),
            CampoTexto(
              etiqueta: 'DNI',
              pista: '31234567',
              controlador: _dni,
              teclado: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CampoTexto(
              etiqueta: 'Fecha de nacimiento',
              pista: 'dd/mm/aaaa',
              controlador: _fechaTexto,
              soloLectura: true,
              alTocar: _elegirFecha,
              icono: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 16),
            CampoTexto(
              etiqueta: 'Email',
              pista: 'juan@email.com',
              controlador: _email,
              teclado: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CampoTexto(
              etiqueta: 'Contraseña',
              pista: 'Mínimo 8 caracteres',
              controlador: _contrasena,
              esContrasena: true,
            ),
            const SizedBox(height: 24),
            BotonPrincipal(texto: 'Crear cuenta', alTocar: _crearCuenta, cargando: _cargando),
          ],
        ),
      ),
    );
  }
}