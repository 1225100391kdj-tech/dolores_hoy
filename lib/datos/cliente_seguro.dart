
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../dominio/excepciones.dart';

// Cliente HTTP que utilizan las cinco APIs.
class ClienteSeguro {
  final http.Client _cliente;
  final Duration espera;
  final int maxBytes;

  ClienteSeguro(
    this._cliente, {
    this.espera = const Duration(seconds: 8),
    this.maxBytes = 1024 * 1024,
  });

  static const _cabeceras = {
    'Accept': 'application/json',
    'User-Agent': 'DoloresHoy/1.0 (curso Flutter UTNG)',
  };

  // Realizar una petición segura.
  Future<dynamic> obtenerJson(Uri uri) async {
    // Solo se permiten conexiones HTTPS.
    if (uri.scheme != 'https') {
      throw const ConexionInseguraException();
    }

    http.Response respuesta;

    try {
      respuesta = await _cliente
          .get(uri, headers: _cabeceras)
          .timeout(espera);
    } on SocketException {
      throw const SinConexionException();
    } on TimeoutException {
      throw const SinConexionException();
    } on http.ClientException {
      throw const SinConexionException();
    }

    // Comprobar el código de respuesta.
    if (respuesta.statusCode < 200 ||
        respuesta.statusCode >= 300) {
      throw ErrorServidorException(respuesta.statusCode);
    }

    // Evitar respuestas demasiado grandes.
    if (respuesta.bodyBytes.length > maxBytes) {
      throw const RespuestaDemasiadoGrandeException();
    }

    // Convertir la respuesta en JSON.
    try {
      return jsonDecode(
        utf8.decode(respuesta.bodyBytes),
      );
    } catch (_) {
      throw const RespuestaInvalidaException();
    }
  }

  // Ocultar claves privadas cuando se muestran URLs en registros.
  static String redactar(Uri uri) {
    const secretos = {
      'api_key',
      'apikey',
      'key',
      'token',
      'access_token'
    };

    final parametros = uri.queryParameters.map(
      (k, v) => MapEntry(
        k,
        secretos.contains(k.toLowerCase()) ? '***' : v,
      ),
    );

    return uri
        .replace(
          queryParameters:
              parametros.isEmpty ? null : parametros,
        )
        .toString()
        .replaceAll('%2A%2A%2A', '***');
  }
}

// Convertir JSON a objetos y controlar errores.
T convertir<T>(T Function() funcion) {
  try {
    return funcion();
  } catch (_) {
    throw const RespuestaInvalidaException();
  }
}
