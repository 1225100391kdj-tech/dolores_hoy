
import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import 'tablero_viewmodel.dart';

class PantallaTablero extends StatefulWidget {
  final TableroViewModel vm;

  const PantallaTablero({
    super.key,
    required this.vm,
  });

  @override
  State<PantallaTablero> createState() =>
      _PantallaTableroState();
}

class _PantallaTableroState extends State<PantallaTablero> {
  final TextEditingController _tema = TextEditingController(
    text: 'Dolores Hidalgo',
  );

  @override
  void initState() {
    super.initState();
    widget.vm.cargarTodo();
  }

  @override
  void dispose() {
    _tema.dispose();
    widget.vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return AnimatedBuilder(
      animation: vm,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            title: const Text('Dolores Hoy'),
            actions: [
              IconButton(
                tooltip: 'Actualizar información',
                onPressed: () => vm.cargarTodo(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          body: RefreshIndicator(
            onRefresh: vm.cargarTodo,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),

              children: [
                const Text(
                  'Información de Dolores Hidalgo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Consulta información de cinco APIs gratuitas.',
                ),

                const SizedBox(height: 18),

                // API 1: Clima
                TarjetaCarga<Clima>(
                  titulo: 'Clima en Dolores Hidalgo',
                  icono: Icons.wb_sunny,
                  carga: vm.clima,
                  construir: (clima) {
                    final (emoji, descripcion) =
                        describirClima(clima.codigo);

                    return Text(
                      '$emoji $descripcion\n'
                      'Temperatura: ${clima.temperatura.toStringAsFixed(1)} °C\n'
                      'Humedad: ${clima.humedad}%\n'
                      'Viento: ${clima.viento.toStringAsFixed(1)} km/h',
                      style: const TextStyle(fontSize: 16),
                    );
                  },
                ),

                // API 2: Tipo de cambio
                TarjetaCarga<TipoCambio>(
                  titulo: 'Tipo de cambio',
                  icono: Icons.attach_money,
                  carga: vm.cambio,
                  construir: (cambio) => Text(
                    '1 USD = \$${cambio.pesosPorUnidad('USD').toStringAsFixed(2)} MXN\n'
                    '1 EUR = \$${cambio.pesosPorUnidad('EUR').toStringAsFixed(2)} MXN\n'
                    'Fecha: ${cambio.fecha.toIso8601String().substring(0, 10)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                // API 3: Días festivos
                TarjetaCarga<List<Festivo>>(
                  titulo: 'Próximos días festivos',
                  icono: Icons.celebration,
                  carga: vm.festivos,
                  construir: (lista) => Text(
                    lista.isEmpty
                        ? 'No hay más días festivos este año.'
                        : lista
                            .map(
                              (f) =>
                                  '${f.fecha.day}/${f.fecha.month}/${f.fecha.year} - ${f.nombre}',
                            )
                            .join('\n'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                // API 4: Wikipedia
                Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.menu_book),
                            SizedBox(width: 10),
                            Text(
                              'Wikipedia',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _tema,
                          maxLength: 80,
                          decoration: InputDecoration(
                            labelText: 'Buscar un tema',
                            hintText: 'Ejemplo: Dolores Hidalgo',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: 'Buscar',
                              onPressed: () =>
                                  vm.buscarWikipedia(_tema.text),
                              icon: const Icon(Icons.search),
                            ),
                          ),
                          onSubmitted: vm.buscarWikipedia,
                        ),

                        const SizedBox(height: 10),

                        _estadoContenido<ResumenWiki>(
                          context,
                          vm.wiki,
                          (wiki) => Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                wiki.titulo,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              if (wiki.urlImagen != null)
                                Image.network(
                                  wiki.urlImagen!,
                                  height: 150,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),

                              const SizedBox(height: 8),

                              Text(wiki.extracto),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // API 5: NASA
                TarjetaCarga<FotoAstronomica>(
                  titulo: 'Foto astronómica de NASA',
                  icono: Icons.rocket_launch,
                  carga: vm.nasa,
                  construir: (foto) => Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        foto.titulo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (foto.urlImagen != null)
                        Image.network(
                          foto.urlImagen!,
                          height: 220,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Text(
                            'No se pudo cargar la imagen.',
                          ),
                        )
                      else
                        const Text(
                          'La NASA publicó un video o una imagen no disponible.',
                        ),

                      const SizedBox(height: 10),

                      Text(
                        foto.explicacion,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Mostrar el contenido según el estado de la API.
Widget _estadoContenido<T>(
  BuildContext context,
  Carga<T> carga,
  Widget Function(T) construir,
) {
  switch (carga.estado) {
    case Estado.cargando:
      return const LinearProgressIndicator();

    case Estado.error:
      return Text(
        carga.error ?? 'Ocurrió un error.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
        ),
      );

    case Estado.listo:
      return construir(carga.dato as T);
  }
}

// Tarjeta reutilizable para las diferentes APIs.
class TarjetaCarga<T> extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Carga<T> carga;
  final Widget Function(T) construir;

  const TarjetaCarga({
    super.key,
    required this.titulo,
    required this.icono,
    required this.carga,
    required this.construir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: Colors.indigo),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _estadoContenido(
              context,
              carga,
              construir,
            ),
          ],
        ),
      ),
    );
  }
}
