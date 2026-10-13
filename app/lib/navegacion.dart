import 'package:flutter/foundation.dart';

// pestaña elegida de la barra de abajo, otras pantallas la pueden cambiar
// 0 inicio, 1 sedes, 2 reservas, 3 perfil
final pestanaActual = ValueNotifier<int>(0);