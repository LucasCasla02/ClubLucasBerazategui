import 'package:flutter/material.dart';

import '../servicios/api.dart';
import '../servicios/auth.dart';
import '../tema.dart';
import '../widgets/aviso_error.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto.dart';
import '../widgets/modal_error.dart';

// cambiar la contraseña desde el perfil (no esta en el figma, se agrego)
class PantallaCambiarContrasena extends StatefulWidget {
  const PantallaCambiarContrasena({super.key});

  @override
  State<PantallaCambiarContrasena> createState() => _PantallaCambiarContrasenaState();
}

class _PantallaCambiarContrasenaState extends State<PantallaCambiarContrasena> {
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _repetir = TextEditingController();
  bool _cargando = false;
  String? _aviso;

  @override
  void dispose() {
    for (final c in [_actual, _nueva, _repetir]) {
      c.dispose();
    }
    super.dispose();
  }

  // revisa los datos antes de mandar nada, devuelve el problema o null si esta todo bien
  String? _validar() {
    if ([_actual, _nueva, _repetir].any((c) => c.text.isEmpty)) return 'Completá todos los campos.';
    if (_nueva.text.length < 8) return 'La contraseña nueva tiene que tener al menos 8 caracteres.';
    if (_nueva.text != _repetir.text) return 'Las contraseñas nuevas no coinciden.';
    if (_nueva.text == _actual.text) return 'La contraseña nueva tiene que ser distinta de la actual.';
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
      _cargando = true;
      _aviso = null;
    });
    try {
      await Auth.cambiarContrasena(actual: _actual.text, nueva: _nueva.text);
      if (!mounted) return;
      // se guarda antes de cerrar la pantalla para poder mostrar el aviso en el perfil
      final mensajero = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      mensajero.showSnackBar(const SnackBar(content: Text('Contraseña actualizada.')));
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
              'SEGURIDAD',
              style: TextStyle(color: tema.colorScheme.secondary, fontSize: 11, letterSpacing: 4, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'CAMBIAR ', style: estiloTitulo(36, tema.colorScheme.onSurface)),
                  TextSpan(text: 'CONTRASEÑA', style: estiloTitulo(36, tema.colorScheme.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Por seguridad, primero confirmá tu contraseña actual.',
              style: TextStyle(color: Colores.gris),
            ),
            const SizedBox(height: 24),
            if (_aviso != null) ...[
              AvisoError(mensaje: _aviso!),
              const SizedBox(height: 16),
            ],
            CampoTexto(etiqueta: 'Contraseña actual', controlador: _actual, esContrasena: true),
            const SizedBox(height: 16),
            CampoTexto(
              etiqueta: 'Contraseña nueva',
              pista: 'Mínimo 8 caracteres',
              controlador: _nueva,
              esContrasena: true,
            ),
            const SizedBox(height: 16),
            CampoTexto(etiqueta: 'Repetir contraseña nueva', controlador: _repetir, esContrasena: true),
            const SizedBox(height: 24),
            BotonPrincipal(texto: 'Guardar contraseña', alTocar: _guardar, cargando: _cargando),
          ],
        ),
      ),
    );
  }
}