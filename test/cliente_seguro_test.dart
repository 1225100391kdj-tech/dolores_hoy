
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:dolores_hoy/datos/cliente_seguro.dart';
import 'package:dolores_hoy/dominio/excepciones.dart';

import 'ayudas.dart';

void main() {
  final https = Uri.parse('https://ejemplo.com/datos');

  test('rechaza direcciones HTTP inseguras', () {
    var llamado = false;

    final cliente = seguro((_) async {
      llamado = true;
      return jsonOk({});
    });

    expect(
      cliente.obtenerJson(
        Uri.parse('http://ejemplo.com'),
      ),
      throwsA(isA<ConexionInseguraException>()),
    );

    expect(llamado, false);
  });

  test('devuelve JSON correctamente con acentos', () async {
    final cliente = seguro(
      (_) async => jsonOk({'nombre': 'Año Nuevo'}),
    );

    final resultado =
        await cliente.obtenerJson(https) as Map<String, dynamic>;

    expect(resultado['nombre'], 'Año Nuevo');
  });

  test('envía cabeceras Accept y User-Agent', () async {
    final cliente = seguro((req) async {
      expect(req.headers['Accept'], 'application/json');

      expect(
        req.headers['User-Agent'],
        contains('DoloresHoy'),
      );

      return jsonOk({});
    });

    await cliente.obtenerJson(https);
  });

  test('error 429 informa límite de peticiones', () {
    final cliente = seguro(
      (_) async => jsonOk({}, 429),
    );

    expect(
      cliente.obtenerJson(https),
      throwsA(
        isA<ErrorServidorException>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Demasiadas'),
        ),
      ),
    );
  });

  test('error 500 genera ErrorServidorException', () {
    final cliente = seguro(
      (_) async => jsonOk({}, 500),
    );

    expect(
      cliente.obtenerJson(https),
      throwsA(
        isA<ErrorServidorException>().having(
          (e) => e.codigo,
          'codigo',
          500,
        ),
      ),
    );
  });

  test('sin conexión genera SinConexionException', () {
    final cliente = seguro(
      (_) async => throw const SocketException('Sin red'),
    );

    expect(
      cliente.obtenerJson(https),
      throwsA(isA<SinConexionException>()),
    );
  });

  test('tiempo de espera genera SinConexionException', () {
    final cliente = seguro(
      (_) async {
        await Future.delayed(
          const Duration(milliseconds: 200),
        );

        return jsonOk({});
      },
      espera: const Duration(milliseconds: 20),
    );

    expect(
      cliente.obtenerJson(https),
      throwsA(isA<SinConexionException>()),
    );
  });

  test('rechaza respuestas demasiado grandes', () {
    final cliente = seguro(
      (_) async => jsonOk({
        'relleno': 'x' * 500,
      }),
      maxBytes: 100,
    );

    expect(
      cliente.obtenerJson(https),
      throwsA(
        isA<RespuestaDemasiadoGrandeException>(),
      ),
    );
  });

  test('rechaza HTML cuando espera JSON', () {
    final cliente = seguro(
      (_) async => http.Response(
        '<html>login wifi</html>',
        200,
      ),
    );

    expect(
      cliente.obtenerJson(https),
      throwsA(isA<RespuestaInvalidaException>()),
    );
  });

  test('oculta claves privadas en las URLs', () {
    final url = Uri.parse(
      'https://api.nasa.gov/planetary/apod?api_key=SECRETO123&dia=hoy',
    );

    final texto = ClienteSeguro.redactar(url);

    expect(texto, isNot(contains('SECRETO123')));
    expect(texto, contains('api_key=***'));
    expect(texto, contains('dia=hoy'));
  });

  test('conserva URLs que no tienen secretos', () {
    expect(
      ClienteSeguro.redactar(https),
      'https://ejemplo.com/datos',
    );
  });
}
