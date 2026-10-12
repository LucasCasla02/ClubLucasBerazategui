import 'package:firebase_auth/firebase_auth.dart';

import 'api.dart';

// inicio y cierre de sesion con firebase
class Auth {
  static final _firebase = FirebaseAuth.instance;

  // avisa cada vez que alguien inicia o cierra sesion
  static Stream<User?> get cambios => _firebase.authStateChanges();

  static Future<void> iniciarSesion(String email, String contrasena) async {
    try {
      await _firebase.signInWithEmailAndPassword(email: email.trim(), password: contrasena);
    } on FirebaseAuthException catch (e) {
      throw _traducir(e);
    }
  }

  static Future<void> cerrarSesion() => _firebase.signOut();

  // pasa los codigos de firebase a mensajes en español
  static ErrorApi _traducir(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return const ErrorApi('Datos incorrectos', 'El email o la contraseña no son correctos.');
      case 'invalid-email':
        return const ErrorApi('Email inválido', 'El email no tiene un formato válido.');
      case 'user-disabled':
        return const ErrorApi('Cuenta deshabilitada', 'Esta cuenta está deshabilitada.');
      case 'too-many-requests':
        return const ErrorApi('Demasiados intentos', 'Hiciste muchos intentos. Esperá unos minutos y probá de nuevo.');
      case 'network-request-failed':
        return errorSinConexion;
      default:
        return const ErrorApi('Error', 'No se pudo iniciar sesión. Intentá de nuevo.');
    }
  }
}