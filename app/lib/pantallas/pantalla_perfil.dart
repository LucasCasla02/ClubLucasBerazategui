import 'package:flutter/material.dart';

import '../servicios/auth.dart';
import '../tema.dart';
import '../widgets/boton_principal.dart';
import '../widgets/titulo_doble.dart';

// provisoria, el perfil completo del cu-05 se arma en el paso 3.12
class PantallaPerfil extends StatelessWidget {
  const PantallaPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const TituloDoble('MI', 'PERFIL'),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Modo oscuro'),
              value: oscuro,
              onChanged: cambiarModoTema,
            ),
            const SizedBox(height: 24),
            BotonPrincipal(texto: 'Cerrar sesión', alTocar: Auth.cerrarSesion),
          ],
        ),
      ),
    );
  }
}