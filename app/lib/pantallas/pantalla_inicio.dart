import 'package:flutter/material.dart';

import '../servicios/api.dart';
import '../servicios/auth.dart';
import '../tema.dart';
import '../widgets/boton_principal.dart';

// pantalla provisoria, se reemplaza por el inicio real en el paso 3.7
class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  String? _nombre;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  // pide el perfil con el token de la sesion
  Future<void> _cargarPerfil() async {
    try {
      final yo = await Api.get('/usuarios/me') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _nombre = yo['nombre'] as String);
    } on ErrorApi catch (e) {
      if (!mounted) return;
      setState(() => _error = e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HOLA,', style: TextStyle(color: Colores.gris, letterSpacing: 4, fontSize: 12)),
              const SizedBox(height: 8),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colores.rojo))
              else if (_nombre == null)
                const CircularProgressIndicator()
              else
                Text(_nombre!.toUpperCase(), style: estiloTitulo(40, tema.colorScheme.secondary)),
              const Spacer(),
              BotonPrincipal(texto: 'Cerrar sesión', alTocar: Auth.cerrarSesion),
            ],
          ),
        ),
      ),
    );
  }
}