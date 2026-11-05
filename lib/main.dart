
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'datos/cliente_seguro.dart';
import 'datos/config_claves.dart';
import 'datos/servicios.dart';
import 'presentacion/pantalla_tablero.dart';
import 'presentacion/tablero_viewmodel.dart';

void main() {
  // Cliente HTTP seguro para las cinco APIs.
  final cliente = ClienteSeguro(http.Client());

  // Configuración de la clave de NASA.
  final claves = ConfigClaves.desdeEntorno();

  // Conectar los servicios con el ViewModel.
  final vm = TableroViewModel(
    clima: ServicioClima(cliente),
    cambio: ServicioCambio(cliente),
    festivos: ServicioFestivos(cliente),
    wikipedia: ServicioWikipedia(cliente),
    nasa: ServicioNasa(cliente, claves),
  );

  // Iniciar la aplicación Flutter.
  runApp(
    MaterialApp(
      title: 'Dolores Hoy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: PantallaTablero(
        vm: vm,
      ),
    ),
  );
}
