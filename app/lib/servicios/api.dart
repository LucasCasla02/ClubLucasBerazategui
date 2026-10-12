import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

// error listo para mostrar al usuario
class ErrorApi implements Exception {
  final String titulo;
  final String mensaje;
  final int? codigo;
  // true si es un problema de internet o del servidor, esos van en el modal
  final bool esDeConexion;

  const ErrorApi(this.titulo, this.mensaje, {this.codigo, this.esDeConexion = false});

  @override
  String toString() => '$titulo: $mensaje';
}

const errorSinConexion = ErrorApi(
  'Error de conectividad',
  'Parece que no está conectado a ninguna red Wi-Fi. Restablezca su conexión e intente otra vez.',
  esDeConexion: true,
);
const errorServidor = ErrorApi(
  'Error del servidor',
  'Parece que hubo un error en el servidor. Por favor vuelva a intentarlo más tarde.',
  esDeConexion: true,
);
const errorDemora = ErrorApi(
  'El servidor no responde',
  'El servidor está tardando demasiado. Intentá de nuevo en unos segundos.',
  esDeConexion: true,
);
const errorSesionVencida = ErrorApi(
  'Sesión vencida',
  'Tu sesión venció. Volvé a iniciar sesión.',
  codigo: 401,
);

// todos los pedidos a la api pasan por aca
class Api {
  // render gratis tarda en despertar, por eso se espera bastante
  static const _espera = Duration(seconds: 30);

  static Future<dynamic> get(String ruta) => _pedir('GET', ruta);
  static Future<dynamic> post(String ruta, Map<String, dynamic> datos) => _pedir('POST', ruta, datos);
  static Future<dynamic> put(String ruta, Map<String, dynamic> datos) => _pedir('PUT', ruta, datos);
  static Future<dynamic> delete(String ruta) => _pedir('DELETE', ruta);

  static Future<dynamic> _pedir(String metodo, String ruta, [Map<String, dynamic>? datos]) async {
    final pedido = http.Request(metodo, Uri.parse('$urlApi$ruta'));
    pedido.headers['Content-Type'] = 'application/json';
    if (datos != null) pedido.body = jsonEncode(datos);

    // si hay sesion iniciada se manda el token de firebase
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario != null) {
      try {
        final token = await usuario.getIdToken();
        pedido.headers['Authorization'] = 'Bearer $token';
      } on FirebaseAuthException catch (e) {
        throw e.code == 'network-request-failed' ? errorSinConexion : errorSesionVencida;
      }
    }

    final http.Response respuesta;
    try {
      respuesta = await http.Response.fromStream(await pedido.send().timeout(_espera));
    } on TimeoutException {
      throw errorDemora;
    } on SocketException catch (e) {
      // 111 es conexion rechazada: hay red pero la api no esta prendida
      throw e.osError?.errorCode == 111 ? errorServidor : errorSinConexion;
    } on http.ClientException {
      throw errorSinConexion;
    }

    return _leer(respuesta);
  }

  static dynamic _leer(http.Response respuesta) {
    final codigo = respuesta.statusCode;

    // se lee como utf8 para que no se rompan las tildes
    final texto = utf8.decode(respuesta.bodyBytes);
    dynamic cuerpo;
    try {
      cuerpo = texto.isEmpty ? null : jsonDecode(texto);
    } on FormatException {
      cuerpo = null;
    }

    if (codigo >= 200 && codigo < 300) return cuerpo;
    if (codigo == 401) throw errorSesionVencida;
    if (codigo >= 500) throw errorServidor;

    // los errores 400, 404, 409 y 422 traen el motivo en "detail"
    final detalle = (cuerpo is Map && cuerpo['detail'] is String)
        ? cuerpo['detail'] as String
        : 'No se pudo completar la operación.';
    throw ErrorApi('Atención', detalle, codigo: codigo);
  }
}