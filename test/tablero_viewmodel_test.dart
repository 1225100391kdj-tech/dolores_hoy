
import 'package:dolores_hoy/datos/config_claves.dart';
import 'package:dolores_hoy/datos/servicios.dart';
import 'package:dolores_hoy/presentacion/tablero_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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
  });

  test('si NASA falla las otras APIs siguen funcionando', () async {
    final vm = crear((r) async {
      if (r.url.host == 'science.nasa.gov') {
        return jsonOk({}, 500);
      }

      return servidorFalso(r);
    });

    await vm.cargarTodo();

    expect(vm.nasa.estado, Estado.error);
    expect(vm.nasa.error, contains('500'));

    expect(vm.clima.estado, Estado.listo);
    expect(vm.cambio.estado, Estado.listo);
    expect(vm.festivos.estado, Estado.listo);
    expect(vm.wiki.estado, Estado.listo);
  });

  test('sin internet todas muestran error', () async {
    final vm = crear(
      (_) async => throw Exception('sin red'),
    );

    await vm.cargarTodo();

    for (final estado in [
      vm.clima.estado,
      vm.cambio.estado,
      vm.festivos.estado,
      vm.wiki.estado,
      vm.nasa.estado,
    ]) {
      expect(estado, Estado.error);
    }

    expect(
      vm.clima.error,
      isNot(contains('sin red')),
    );
  });

  test('cargarTodo anuncia cargando antes de terminar', () async {
    final vm = crear(servidorFalso);

    final vistos = <Estado>[];

    vm.addListener(() {
      vistos.add(vm.clima.estado);
    });

    await vm.cargarTodo();

    expect(vistos.first, Estado.cargando);
    expect(vistos.last, Estado.listo);
  });
}
