import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'api.dart';

// notificaciones push (cu-24): el celular le da su token a la api,
// y la api le pide a firebase que mande los recordatorios a ese token
class Notificaciones {
  static final _fcm = FirebaseMessaging.instance;
  static StreamSubscription<String>? _cambiosDeToken;

  // se llama al entrar con sesion: pide permiso y guarda el token en la api
  static Future<void> activar() async {
    try {
      // en android 13 o mas nuevo muestra el cartel "permitir notificaciones"
      await _fcm.requestPermission();
      final token = await _fcm.getToken();
      if (token != null) await _guardar(token);
      // firebase a veces cambia el token: se vuelve a mandar el nuevo
      _cambiosDeToken ??= _fcm.onTokenRefresh.listen(_guardar);
    } catch (_) {
      // si falla, la app funciona igual, solo que sin avisos
    }
  }

  // al cerrar sesion: este celular deja de recibir avisos de esa cuenta
  static Future<void> desactivar() async {
    await _cambiosDeToken?.cancel();
    _cambiosDeToken = null;
    try {
      // se espera poco: cerrar sesion no puede quedar trabado si no hay internet
      await Api.put('/usuarios/me/token-fcm', {'token': null}).timeout(const Duration(seconds: 3));
    } catch (_) {
      // sin conexion no pasa nada: el token se reemplaza en el proximo inicio de sesion
    }
  }

  static Future<void> _guardar(String token) async {
    try {
      await Api.put('/usuarios/me/token-fcm', {'token': token});
    } on ErrorApi {
      // se reintenta la proxima vez que entre a la app
    }
  }
}