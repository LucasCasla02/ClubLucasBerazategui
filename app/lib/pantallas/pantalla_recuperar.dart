import 'package:flutter/material.dart';

import '../servicios/api.dart';
import '../servicios/auth.dart';
import '../tema.dart';
import '../widgets/aviso_error.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto.dart';
import '../widgets/modal_error.dart';

class PantallaRecuperar extends StatefulWidget {
  // el email que ya estaba escrito en el login, para no tipearlo de nuevo
  final String emailInicial;

  const PantallaRecuperar({super.key, this.emailInicial = ''});

  @override
  State<PantallaRecuperar> createState() => _PantallaRecuperarState();
}

class _PantallaRecuperarState extends State<PantallaRecuperar> {
  late final _email = TextEditingController(text: widget.emailInicial);
  bool _cargando = false;
  String? _aviso;
  // cuando se manda el enlace se guarda a que email fue
  String? _enviadoA;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _aviso = 'Ingresá tu email.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _aviso = 'El email no tiene un formato válido.');
      return;
    }

    setState(() {
      _cargando = true;
      _aviso = null;
    });
    try {
      await Auth.recuperarContrasena(email);
      if (!mounted) return;
      setState(() => _enviadoA = email);
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
              'RECUPERACIÓN',
              style: TextStyle(color: tema.colorScheme.secondary, fontSize: 11, letterSpacing: 4, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'OLVIDÉ MI ', style: estiloTitulo(36, tema.colorScheme.onSurface)),
                  TextSpan(text: 'CONTRASEÑA', style: estiloTitulo(36, tema.colorScheme.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_enviadoA == null) ..._formulario() else _confirmacion(tema),
          ],
        ),
      ),
    );
  }

  List<Widget> _formulario() {
    return [
      const Text(
        'Ingresá tu email y te enviaremos un enlace para crear una contraseña nueva.',
        style: TextStyle(color: Colores.gris),
      ),
      const SizedBox(height: 24),
      if (_aviso != null) ...[
        AvisoError(mensaje: _aviso!),
        const SizedBox(height: 16),
      ],
      CampoTexto(
        etiqueta: 'Email',
        pista: 'Tu email registrado',
        controlador: _email,
        teclado: TextInputType.emailAddress,
      ),
      const SizedBox(height: 24),
      BotonPrincipal(texto: 'Enviar enlace', alTocar: _enviar, cargando: _cargando),
    ];
  }

  // tarjeta de "enlace enviado", como en el figma
  Widget _confirmacion(ThemeData tema) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tema.brightness == Brightness.dark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        children: [
          Icon(Icons.mark_email_read_outlined, size: 48, color: tema.colorScheme.secondary),
          const SizedBox(height: 16),
          const Text('¡Enlace enviado!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Revisá tu bandeja en '),
                TextSpan(
                  text: _enviadoA,
                  style: TextStyle(color: tema.colorScheme.secondary, fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: '. Si no lo ves, fijate en spam.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          BotonPrincipal(texto: 'Volver al login', alTocar: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}