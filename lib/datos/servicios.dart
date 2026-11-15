
import '../dominio/excepciones.dart';
import '../dominio/modelos.dart';

import 'cliente_seguro.dart';
import 'config_claves.dart';

// API 1: Open-Meteo.
class ServicioClima {
  final ClienteSeguro _cliente;
  ServicioClima(this._cliente);

  Future<Clima> actual({
    double lat = 21.1561,
    double lon = -100.9319,
  }) async {
    if (!lat.isFinite ||
        !lon.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      throw const EntradaInvalidaException(
        'coordenadas fuera de rango',
      );
    }

    final json = await _cliente.obtenerJson(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$lat',
        'longitude': '$lon',
        'current':
            'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
        'timezone': 'America/Mexico_City',
      }),
    );

    return convertir(
      () => Clima.desdeJson(json as Map<String, dynamic>),
    );
  }
}

// API 2: Frankfurter.
class ServicioCambio {
  final ClienteSeguro _cliente;
  ServicioCambio(this._cliente);

  Future<TipoCambio> deMxn() async {
    final json = await _cliente.obtenerJson(
      Uri.https('api.frankfurter.dev', '/v1/latest', {
        'base': 'MXN',
        'symbols': 'USD,EUR',
      }),
    );

    return convertir(() {
      final cambio = TipoCambio.desdeJson(
        json as Map<String, dynamic>,
      );

      if (cambio.tasas['USD'] == null ||
          cambio.tasas['EUR'] == null ||
          cambio.tasas.values.any(
            (valor) => valor <= 0 || !valor.isFinite,
          )) {
        throw const RespuestaInvalidaException();
      }

      return cambio;
    });
  }
}

// API 3: Nager.Date.
class ServicioFestivos {
  final ClienteSeguro _cliente;
  ServicioFestivos(this._cliente);

  Future<List<Festivo>> proximos({
    int? anio,
    DateTime? hoy,
    int cuantos = 3,
  }) async {
    final ahora = hoy ?? DateTime.now();
    final anioConsulta = anio ?? ahora.year;

    if (anioConsulta < 2000 ||
        anioConsulta > 2100 ||
        cuantos < 0 ||
        cuantos > 100) {
      throw const EntradaInvalidaException(
        'año o cantidad fuera de rango',
      );
    }

    final json = await _cliente.obtenerJson(
      Uri.https(
        'date.nager.at',
        '/api/v3/PublicHolidays/$anioConsulta/MX',
      ),
    );

    final todos = convertir(
      () => (json as List)
          .map(
            (elemento) => Festivo.desdeJson(
              elemento as Map<String, dynamic>,
            ),
          )
          .toList(),
    );

    final fechaActual = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    );

    final futuros = todos
        .where(
          (festivo) => !festivo.fecha.isBefore(fechaActual),
        )
        .toList()
      ..sort(
        (a, b) => a.fecha.compareTo(b.fecha),
      );

    return futuros.take(cuantos).toList();
  }
}

// API 4: Wikipedia.
class ServicioWikipedia {
  final ClienteSeguro _cliente;
  ServicioWikipedia(this._cliente);

  static String normalizarTema(String tema) {
    final texto = tema.trim();

    if (texto.isEmpty) {
      throw const EntradaInvalidaException(
        'escribe un tema',
      );
    }

    if (texto.length > 80) {
      throw const EntradaInvalidaException(
        'tema demasiado largo',
      );
    }

    if (texto.contains(RegExp(r'[\x00-\x1F]'))) {
      throw const EntradaInvalidaException(
        'caracteres no permitidos',
      );
    }

    return texto.replaceAll(' ', '_');
  }

  Future<ResumenWiki> resumen(String tema) async {
    final texto = normalizarTema(tema);

    final uri = Uri(
      scheme: 'https',
      host: 'es.wikipedia.org',
      pathSegments: [
        'api',
        'rest_v1',
        'page',
        'summary',
        texto,
      ],
    );

    final json = await _cliente.obtenerJson(uri);

    return convertir(
      () => ResumenWiki.desdeJson(
        json as Map<String, dynamic>,
      ),
    );
  }
}

// API 5: NASA APOD.
// Usa el endpoint nuevo y conserva la validacion de claves.
class ServicioNasa {
  final ClienteSeguro _cliente;
  final ConfigClaves _claves;

  ServicioNasa(this._cliente, this._claves);

  Future<FotoAstronomica> fotoDelDia() async {
    _claves.validar();

    final respuesta = await _cliente.obtenerJson(
      Uri.https(
        'science.nasa.gov',
        '/wp-json/wp/v2/apod-basic',
        {
          'per_page': '1',
          'api_key': _claves.nasa,
        },
      ),
    );

    return convertir(() {
      final Map<String, dynamic> datos;

      if (respuesta is List) {
        if (respuesta.isEmpty) {
          throw const RespuestaInvalidaException();
        }

        datos = Map<String, dynamic>.from(
          respuesta.first as Map,
        );
      } else {
        datos = Map<String, dynamic>.from(
          respuesta as Map,
        );
      }

      // hdurl contiene la fotografia cuando esta disponible.
      // Se rechazan imagenes HTTP inseguras.
      if (datos['media_type'] == 'image' &&
          datos.containsKey('hdurl')) {
        final imagen = datos['hdurl'];

        datos['url'] = imagen is String &&
                Uri.tryParse(imagen)?.scheme == 'https'
            ? imagen
            : null;
      } else if (datos['media_type'] == 'image' &&
          datos['url'] is String &&
          (datos['url'] as String)
              .startsWith('https://science.nasa.gov/')) {
        datos['url'] = null;
      }

      return FotoAstronomica.desdeJson(datos);
    });
  }
}
