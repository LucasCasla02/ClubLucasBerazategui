import 'package:flutter/material.dart';

import '../tema.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto.dart';
import '../widgets/modal_error.dart';

// pantalla provisoria para probar el tema y los widgets, se borra cuando este el login
class PantallaMuestra extends StatefulWidget {
  const PantallaMuestra({super.key});

  @override
  State<PantallaMuestra> createState() => _PantallaMuestraState();
}

class _PantallaMuestraState extends State<PantallaMuestra> {
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _email.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  // simula un login de 2 segundos para ver el circulito
  Future<void> _probarBoton() async {
    setState(() => _cargando = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('CLUB', style: estiloTitulo(40, tema.colorScheme.onSurface)),
            Text('LUCAS BERAZATEGUI', style: estiloTitulo(32, tema.colorScheme.secondary)),
            const SizedBox(height: 4),
            const Text('Gestión de espacios deportivos'),
            const SizedBox(height: 4),
            Text('Moron_Rivadavia_17500_Futbol_F5_1', style: estiloCodigo(Colores.gris)),
            const SizedBox(height: 32),
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
            BotonPrincipal(texto: 'Iniciar sesión', alTocar: _probarBoton, cargando: _cargando),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => mostrarError(
                context,
                titulo: 'Error de conectividad',
                mensaje: 'Parece que no está conectado a ninguna red Wi-Fi. Restablezca su conexión e intente otra vez.',
              ),
              child: const Text('Probar modal de error'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Modo oscuro'),
              value: oscuro,
              onChanged: cambiarModoTema,
            ),
          ],
        ),
      ),
    );
  }
}