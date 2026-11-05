
import 'package:flutter/foundation.dart';

import '../datos/servicios.dart';
import '../dominio/excepciones.dart';
import '../dominio/modelos.dart';

// Estados de cada sección del tablero.
enum Estado { cargando, listo, error }

// Representa el resultado de consultar una API.
class Carga<T> {
  final Estado estado;
  final T? dato;
  final String? error;

  const Carga._(this.estado, this.dato, this.error);

  const Carga.cargando()
      : this._(Estado.cargando, null, null);

  const Carga.listo(T dato)
      : this._(Estado.listo, dato, null);

  const Carga.fallo(String error)
      : this._(Estado.error, null, error);
}

// Controla las cinco secciones de la aplicación.
class TableroViewModel extends ChangeNotifier {
  final ServicioClima _clima;
  final ServicioCambio _cambio;
  final ServicioFestivos _festivos;
  final ServicioWikipedia _wikipedia;
  final ServicioNasa _nasa;

  TableroViewModel({
    required ServicioClima clima,
    required ServicioCambio cambio,
    required ServicioFestivos festivos,
    required ServicioWikipedia wikipedia,
    required ServicioNasa nasa,
  })  : _clima = clima,
        _cambio = cambio,
        _festivos = festivos,
        _wikipedia = wikipedia,
        _nasa = nasa;

  // Estado de cada API.
  Carga<Clima> clima = const Carga.cargando();
  Carga<TipoCambio> cambio = const Carga.cargando();
  Carga<List<Festivo>> festivos = const Carga.cargando();
  Carga<ResumenWiki> wiki = const Carga.cargando();
  Carga<FotoAstronomica> nasa = const Carga.cargando();

  String temaWikipedia = 'Dolores Hidalgo';

  // Consultar las cinco APIs.
  Future<void> cargarTodo() async {
    clima = const Carga.cargando();
    cambio = const Carga.cargando();
    festivos = const Carga.cargando();
    wiki = const Carga.cargando();
    nasa = const Carga.cargando();

    notifyListeners();

    await Future.wait([
      _cargar(
        () => _clima.actual(),
        (Carga<Clima> resultado) => clima = resultado,
      ),
      _cargar(
        () => _cambio.deMxn(),
        (Carga<TipoCambio> resultado) => cambio = resultado,
      ),
      _cargar(
        () => _festivos.proximos(),
        (Carga<List<Festivo>> resultado) =>
            festivos = resultado,
      ),
      _cargar(
        () => _wikipedia.resumen(temaWikipedia),
        (Carga<ResumenWiki> resultado) => wiki = resultado,
      ),
      _cargar(
        () => _nasa.fotoDelDia(),
        (Carga<FotoAstronomica> resultado) => nasa = resultado,
      ),
    ]);
  }

  // Buscar otro tema en Wikipedia.
  Future<void> buscarWikipedia(String tema) async {
    temaWikipedia = tema;
    wiki = const Carga.cargando();

    notifyListeners();

    await _cargar(
      () => _wikipedia.resumen(tema),
      (Carga<ResumenWiki> resultado) => wiki = resultado,
    );
  }

  // Manejar cada consulta por separado.
  Future<void> _cargar<T>(
    Future<T> Function() pedir,
    void Function(Carga<T>) poner,
  ) async {
    try {
      poner(Carga.listo(await pedir()));
    } catch (e) {
      poner(Carga.fallo(mensajeSeguro(e)));
    }

    notifyListeners();
  }
}
