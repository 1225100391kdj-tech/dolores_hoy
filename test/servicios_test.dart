
import 'package:flutter_test/flutter_test.dart';

import 'package:dolores_hoy/datos/config_claves.dart';
import 'package:dolores_hoy/datos/servicios.dart';
import 'package:dolores_hoy/dominio/excepciones.dart';
import 'package:dolores_hoy/dominio/modelos.dart';

import 'ayudas.dart';

void main() {
  group('API 1: Clima', () {
    test('respuesta correcta', () async {
      final servicio = ServicioClima(
        seguro((req) async {
          expect(req.url.host, 'api.open-meteo.com');

          expect(
            req.url.queryParameters['latitude'],
            '21.1561',
          );

          return jsonOk(jsonClima);
        }),
      );

      final clima = await servicio.actual();

      expect(clima.temperatura, 24.3);
      expect(clima.humedad, 41);
      expect(clima.codigo, 1);
    });

    test('rechaza coordenadas inválidas', () {
      final servicio = ServicioClima(
        seguro((_) async => jsonOk(jsonClima)),
      );

      expect(
        servicio.actual(lat: 200),
        throwsA(isA<EntradaInvalidaException>()),
      );
    });

    test('rechaza JSON incompleto', () {
      final servicio = ServicioClima(
        seguro((_) async => jsonOk({'otra': 1})),
      );

      expect(
        servicio.actual(),
        throwsA(isA<RespuestaInvalidaException>()),
      );
    });

    test('traduce códigos del clima', () {
      expect(describirClima(0).$2, 'Despejado');
      expect(describirClima(63).$2, 'Lluvia');
      expect(describirClima(95).$2, 'Tormenta');
    });
  });

  group('API 2: Tipo de cambio', () {
    test('calcula pesos por dólar y euro', () async {
      final servicio = ServicioCambio(
        seguro((_) async => jsonOk({
          'base': 'MXN',
          'date': '2026-10-28',
          'rates': {
            'USD': 0.05,
            'EUR': 0.04,
          },
        })),
      );

      final cambio = await servicio.deMxn();

      expect(
        cambio.pesosPorUnidad('USD'),
        closeTo(20, 0.0001),
      );

      expect(
        cambio.pesosPorUnidad('EUR'),
        closeTo(25, 0.0001),
      );
    });

    test('rechaza tasas inválidas', () {
      final servicio = ServicioCambio(
        seguro((_) async => jsonOk({
          'base': 'MXN',
          'date': '2026-10-28',
          'rates': {
            'USD': 0,
            'EUR': 0.04,
          },
        })),
      );

      expect(
        servicio.deMxn(),
        throwsA(isA<RespuestaInvalidaException>()),
      );
    });
  });

  group('API 3: Días festivos', () {
    test('muestra próximos días festivos', () async {
      final servicio = ServicioFestivos(
        seguro((req) async {
          expect(
            req.url.path,
            '/api/v3/PublicHolidays/2026/MX',
          );

          return jsonOk(jsonFestivos);
        }),
      );

      final resultado = await servicio.proximos(
        hoy: DateTime(2026, 10, 29),
        cuantos: 2,
      );

      expect(
        resultado.map((f) => f.nombre),
        ['Día de la Revolución', 'Navidad'],
      );
    });

    test('incluye el día festivo actual', () async {
      final servicio = ServicioFestivos(
        seguro((_) async => jsonOk(jsonFestivos)),
      );

      final resultado = await servicio.proximos(
        hoy: DateTime(2026, 12, 25),
        cuantos: 5,
      );

      expect(resultado.single.nombre, 'Navidad');
    });

    test('rechaza años fuera de rango', () {
      final servicio = ServicioFestivos(
        seguro((_) async => jsonOk(jsonFestivos)),
      );

      expect(
        servicio.proximos(anio: 3000),
        throwsA(isA<EntradaInvalidaException>()),
      );
    });
  });

  group('API 4: Wikipedia', () {
    test('busca información de Dolores Hidalgo', () async {
      final servicio = ServicioWikipedia(
        seguro((req) async {
          expect(req.url.host, 'es.wikipedia.org');

          expect(
            req.url.pathSegments.last,
            'Dolores_Hidalgo',
          );

          return jsonOk(jsonWiki);
        }),
      );

      final wiki = await servicio.resumen(
        'Dolores Hidalgo',
      );

      expect(wiki.titulo, 'Dolores Hidalgo');
      expect(wiki.urlImagen, startsWith('https://'));
    });

    test('rechaza entradas vacías', () {
      expect(
        () => ServicioWikipedia.normalizarTema('   '),
        throwsA(isA<EntradaInvalidaException>()),
      );
    });

    test('rechaza entradas demasiado largas', () {
      expect(
        () => ServicioWikipedia.normalizarTema('a' * 81),
        throwsA(isA<EntradaInvalidaException>()),
      );
    });

    test('rechaza caracteres no permitidos', () {
      expect(
        () => ServicioWikipedia.normalizarTema(
          'hola\nmundo',
        ),
        throwsA(isA<EntradaInvalidaException>()),
      );
    });

    test('rechaza imágenes HTTP', () async {
      final servicio = ServicioWikipedia(
        seguro((_) async => jsonOk({
          'title': 'X',
          'extract': 'Y',
          'thumbnail': {
            'source': 'http://inseguro.com/imagen.jpg',
          },
        })),
      );

      final wiki = await servicio.resumen('X');

      expect(wiki.urlImagen, isNull);
    });
  });

  group('API 5: NASA', () {
    test('envía correctamente la clave API', () async {
      final servicio = ServicioNasa(
        seguro((req) async {
          expect(
            req.url.queryParameters['api_key'],
            'MI_CLAVE',
          );

          return jsonOk(jsonNasa);
        }),
        const ConfigClaves(nasa: 'MI_CLAVE'),
      );

      final foto = await servicio.fotoDelDia();

      expect(foto.titulo, 'Nebulosa de ejemplo');
    });

    test('no consulta NASA sin clave', () {
      var llamado = false;

      final servicio = ServicioNasa(
        seguro((_) async {
          llamado = true;
          return jsonOk(jsonNasa);
        }),
        const ConfigClaves(nasa: '  '),
      );

      expect(
        servicio.fotoDelDia(),
        throwsA(isA<ClaveFaltanteException>()),
      );

      expect(llamado, false);
    });

    test('no muestra videos como imágenes', () async {
      final servicio = ServicioNasa(
        seguro((_) async => jsonOk({
          ...jsonNasa,
          'media_type': 'video',
          'url': 'https://youtube.com/video',
        })),
        const ConfigClaves(nasa: 'K'),
      );

      final foto = await servicio.fotoDelDia();

      expect(foto.urlImagen, isNull);
    });

    test('rechaza imágenes HTTP inseguras', () async {
      final servicio = ServicioNasa(
        seguro((_) async => jsonOk({
          ...jsonNasa,
          'url': 'http://apod.nasa.gov/imagen.jpg',
        })),
        const ConfigClaves(nasa: 'K'),
      );

      final foto = await servicio.fotoDelDia();

      expect(foto.urlImagen, isNull);
    });

    test('detecta clave inválida', () {
      final servicio = ServicioNasa(
        seguro((_) async => jsonOk({}, 403)),
        const ConfigClaves(nasa: 'MALA'),
      );

      expect(
        servicio.fotoDelDia(),
        throwsA(
          isA<ErrorServidorException>().having(
            (e) => e.toString(),
            'mensaje',
            contains('clave'),
          ),
        ),
      );
    });
  });
}
