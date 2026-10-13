import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'api.dart';

// inicio, cierre de sesion y registro con firebase
class Auth {
  static final _firebase = FirebaseAuth.instance;

  // avisa cada vez que alguien inicia o cierra sesion
  static final Stream<User?> cambios = _firebase.authStateChanges();

  // true mientras se crea una cuenta, asi la puerta no entra antes de tiempo
  static final registrando = ValueNotifier<bool>(false);

  static Future<void> iniciarSesion(String email, String contrasena) async {
    try {
      await _firebase.signInWithEmailAndPassword(email: email.trim(), password: contrasena);
    } on FirebaseAuthException catch (e) {
      throw _traducir(e, 'No se pudo iniciar sesión. Intentá de nuevo.');
    }
  }

  // crea la cuenta en firebase y despues el perfil en la api
  static Future<void> registrar({
    required String email,
    required String contrasena,
    required Map<String, dynamic> perfil,
  }) async {
    registrando.value = true;
    try {
      try {
        await _firebase.createUserWithEmailAndPassword(email: email.trim(), password: contrasena);
      } on FirebaseAuthException catch (e) {
        throw _traducir(e, 'No se pudo crear la cuenta. Intentá de nuevo.');
      }
      try {
        await Api.post('/usuarios', perfil);
      } on ErrorApi {
        // si la api no creo el perfil se deshace la cuenta para no dejarla a medias
        await _deshacerCuenta();
        rethrow;
      }
    } finally {
      registrando.value = false;
    }
  }

  static Future<void> cerrarSesion() => _firebase.signOut();

  // manda el mail de firebase para crear una contraseña nueva
  static Future<void> recuperarContrasena(String email) async {
    try {
      // el mail llega en español
      await _firebase.setLanguageCode('es');
      await _firebase.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _traducir(e, 'No se pudo enviar el enlace. Intentá de nuevo.');
    }
  }

  // firebase pide confirmar la contraseña actual antes de cambiarla
  static Future<void> cambiarContrasena({required String actual, required String nueva}) async {
    final usuario = _firebase.currentUser;
    final email = usuario?.email;
    if (usuario == null || email == null) throw errorSesionVencida;

    try {
      final credencial = EmailAuthProvider.credential(email: email, password: actual);
      await usuario.reauthenticateWithCredential(credencial);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw const ErrorApi('Contraseña incorrecta', 'La contraseña actual no es correcta.');
      }
      throw _traducir(e, 'No se pudo cambiar la contraseña. Intentá de nuevo.');
    }

    try {
      await usuario.updatePassword(nueva);
    } on FirebaseAuthException catch (e) {
      throw _traducir(e, 'No se pudo cambiar la contraseña. Intentá de nuevo.');
    }
  }

  static Future<void> _deshacerCuenta() async {
    try {
      await _firebase.currentUser?.delete();
    } on FirebaseAuthException {
      // si la api ya la borro (dni o email repetido) no hay nada que hacer
    }
    await _firebase.signOut();
  }

  // pasa los codigos de firebase a mensajes en español
  static ErrorApi _traducir(FirebaseAuthException e, String porDefecto) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return const ErrorApi('Datos incorrectos', 'El email o la contraseña no son correctos.');
      case 'email-already-in-use':
        return const ErrorApi('Email registrado', 'Ya existe una cuenta con ese email.');
      case 'weak-password':
        return const ErrorApi('Contraseña débil', 'La contraseña es muy débil. Usá al menos 8 caracteres.');
      case 'invalid-email':
        return const ErrorApi('Email inválido', 'El email no tiene un formato válido.');
      case 'user-disabled':
        return const ErrorApi('Cuenta deshabilitada', 'Esta cuenta está deshabilitada.');
      case 'too-many-requests':
        return const ErrorApi('Demasiados intentos', 'Hiciste muchos intentos. Esperá unos minutos y probá de nuevo.');
      case 'network-request-failed':
        return errorSinConexion;
      default:
        return ErrorApi('Error', porDefecto);
    }
  }
}