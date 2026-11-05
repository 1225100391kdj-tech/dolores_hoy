
import 'package:flutter_test/flutter_test.dart';

import 'package:dolores_hoy/datos/config_claves.dart';
import 'package:dolores_hoy/dominio/excepciones.dart';
import 'package:dolores_hoy/dominio/modelos.dart';

void main() {
  test('oculta las claves privadas', () {
    const configuracion = ConfigClaves(
      nasa: 'abcdef123456',
    );

    expect(
      configuracion.toString(),
      isNot(contains('abcdef123456')),
    );

    expect(
      configuracion.toString(),
      contains('ab***56'),
    );

    expect(
      const ConfigClaves(nasa: 'abc').toString(),
      contains('****'),
    );
  });

  test('identifica la clave DEMO de NASA', () {
    expect(
      const ConfigClaves(
        nasa: 'DEMO_KEY',
      ).usaClaveDemo,
      true,
    );

    expect(
      const ConfigClaves(
        nasa: 'MI_CLAVE',
      ).usaClaveDemo,
      false,
    );
  });

  test('rechaza claves vacías', () {
    expect(
      () => const ConfigClaves(
        nasa: '',
      ).validar(),
      throwsA(isA<ClaveFaltanteException>()),
    );
  });

  test('los errores no muestran información privada', () {
    expect(
      mensajeSeguro(
        const SinConexionException(),
      ),
      contains('conexión'),
    );

    final mensaje = mensajeSeguro(
      StateError(
        'clave=SECRETO en /home/usuario/app',
      ),
    );

    expect(
      mensaje,
      isNot(contains('SECRETO')),
    );

    expect(
      mensaje,
      isNot(contains('/home')),
    );

    expect(
      mensaje,
      contains('inesperado'),
    );
  });

  test('solo permite imágenes HTTPS', () {
    expect(
      soloHttps('https://a.com/imagen.jpg'),
      'https://a.com/imagen.jpg',
    );

    expect(
      soloHttps('http://a.com/imagen.jpg'),
      isNull,
    );

    expect(
      soloHttps('javascript:alert(1)'),
      isNull,
    );

    expect(
      soloHttps(null),
      isNull,
    );
  });
}
