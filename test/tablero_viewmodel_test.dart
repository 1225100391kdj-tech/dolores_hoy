
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:dolores_hoy/datos/config_claves.dart';
import 'package:dolores_hoy/datos/servicios.dart';
import 'package:dolores_hoy/presentacion/tablero_viewmodel.dart';

import 'ayudas.dart';

TableroViewModel crear(
  Future<http.Response> Function(http.Request) manejador,
) {
  final cliente = seguro(manejador);

  return TableroViewModel(
    clima: ServicioClima(cliente),
    cambio: ServicioCambio(cliente),
    festivos: ServicioFestivos(cliente),
    wikipedia: ServicioWikipedia(cliente),
    nasa: ServicioNasa(
      cliente,
      const ConfigClaves(nasa: 'DEMO_KEY'),
    ),
  );
}

void main() {
  test('las cinco APIs cargan correctamente', () async {
    final vm = crear(servidorFalso);

    await vm.cargarTodo();

    expect(vm.clima.estado, Estado.listo);
    expect(vm.cambio.estado, Estado.listo);
    expect(vm.festivos.estado, Estado.listo);
    expect(vm.wiki.estado, Estado.listo);
    expect(vm.nasa.estado, Estado.listo);

    expect(vm.clima.dato!.temperatura, 24.3);

    vm.dispose();
  });

  test('si NASA falla las otras APIs siguen funcionando', () async {
    final vm = crear((req) async {
      if (req.url.host == 'api.nasa.gov') {
        return jsonOk({}, 500);
      }

      return servidorFalso(req);
    });

    await vm.cargarTodo();

    expect(vm.nasa.estado, Estado.error);
    expect(vm.nasa.error, contains('500'));

    expect(vm.clima.estado, Estado.listo);
    expect(vm.cambio.estado, Estado.listo);
    expect(vm.festivos.estado, Estado.listo);
    expect(vm.wiki.estado, Estado.listo);

    vm.dispose();
  });

  test('los errores inesperados no revelan secretos', () async {
    final vm = crear(
      (_) async => throw Exception('sin red - secreto'),
    );

    await vm.cargarTodo();

    expect(vm.clima.estado, Estado.error);
    expect(vm.cambio.estado, Estado.error);
    expect(vm.festivos.estado, Estado.error);
    expect(vm.wiki.estado, Estado.error);
    expect(vm.nasa.estado, Estado.error);

    expect(
      vm.clima.error,
      isNot(contains('secreto')),
    );

    expect(
      vm.clima.error,
      contains('inesperado'),
    );

    vm.dispose();
  });

  test('notifica los estados cargando y listo', () async {
    final vm = crear(servidorFalso);

    final estados = <Estado>[];

    vm.addListener(() {
      estados.add(vm.clima.estado);
    });

    await vm.cargarTodo();

    expect(estados.first, Estado.cargando);
    expect(estados.last, Estado.listo);

    vm.dispose();
  });
}
