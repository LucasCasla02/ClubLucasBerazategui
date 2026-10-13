import 'package:flutter/material.dart';

import '../navegacion.dart';
import '../tema.dart';
import 'pantalla_inicio.dart';
import 'pantalla_perfil.dart';
import 'pantalla_reservas.dart';
import 'pantalla_sedes.dart';

// pantalla con la barra de abajo y las 4 pestañas
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  static const _pantallas = [
    PantallaInicio(),
    PantallaSedes(),
    PantallaReservas(),
    PantallaPerfil(),
  ];

  @override
  void initState() {
    super.initState();
    // al iniciar sesion siempre arranca en inicio
    pestanaActual.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pestanaActual,
      builder: (context, pestana, _) => Scaffold(
        // indexedstack deja vivas las 4 pestañas, asi no se recargan al volver
        body: IndexedStack(index: pestana, children: _pantallas),
        bottomNavigationBar: NavigationBar(
          selectedIndex: pestana,
          onDestinationSelected: (indice) => pestanaActual.value = indice,
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Colores.lima,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Colores.negro),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.apartment_outlined),
              selectedIcon: Icon(Icons.apartment, color: Colores.negro),
              label: 'Sedes',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: Colores.negro),
              label: 'Reservas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Colores.negro),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}