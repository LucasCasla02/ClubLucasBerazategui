import 'package:flutter/material.dart';

import '../servicios/api.dart';
import '../servicios/auth.dart';
import '../tema.dart';
import '../widgets/aviso_error.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto.dart';
import '../widgets/modal_error.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  bool _cargando = false;
  String? _aviso;

  @override
  void dispose() {
    _email.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    FocusScope.of(context).unfocus();

    // campos vacios, como en el figma
    final sinEmail = _email.text.trim().isEmpty;
    final sinContrasena = _contrasena.text.isEmpty;
    if (sinEmail || sinContrasena) {
      setState(() {
        _aviso = sinEmail && sinContrasena
            ? 'Completá todos los campos.'
            : sinEmail
                ? 'Ingresá tu email.'
                : 'Ingresá tu contraseña.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _aviso = null;
    });
    try {
      // si sale bien, la puerta de main.dart cambia sola a la pantalla de inicio
      await Auth.iniciarSesion(_email.text, _contrasena.text);
    } on ErrorApi catch (e) {
      if (!mounted) return;
      if (e.esDeConexion) {
        await mostrarError(context, titulo: e.titulo, mensaje: e.mensaje);
      } else {
        setState(() => _aviso = e.mensaje);
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
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Text(
              'BIENVENIDO A',
              style: TextStyle(color: tema.colorScheme.secondary, fontSize: 11, letterSpacing: 4, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('CLUB', style: estiloTitulo(44, tema.colorScheme.onSurface)),
            Text('LUCAS BERAZATEGUI', style: estiloTitulo(36, tema.colorScheme.secondary)),
            const SizedBox(height: 4),
            const Text('Gestión de espacios deportivos', style: TextStyle(color: Colores.gris)),
            const SizedBox(height: 32),
            if (_aviso != null) ...[
              AvisoError(mensaje: _aviso!),
              const SizedBox(height: 16),
            ],
            CampoTexto(
              etiqueta: 'Email',
              pista: 'juan@email.com',
              controlador: _email,
              teclado: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CampoTexto(
              etiqueta: 'Contraseña',
              pista: 'Tu contraseña',
              controlador: _contrasena,
              esContrasena: true,
            ),
            Align(
              alignment: Alignment.centerRight,
              // se conecta en la parte c
              child: TextButton(onPressed: () {}, child: const Text('¿Olvidaste tu contraseña?')),
            ),
            const SizedBox(height: 8),
            BotonPrincipal(texto: 'Iniciar sesión', alTocar: _ingresar, cargando: _cargando),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿No tenés cuenta?'),
                // se conecta en la parte b
                TextButton(onPressed: () {}, child: const Text('COMENZAR →')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}