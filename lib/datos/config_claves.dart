
import '../dominio/excepciones.dart';

// Configuración de claves de las APIs.
class ConfigClaves {
  final String nasa;

  const ConfigClaves({
    required this.nasa,
  });

  // Obtiene la clave configurada al ejecutar Flutter.
  factory ConfigClaves.desdeEntorno() =>
      const ConfigClaves(
        nasa: String.fromEnvironment(
          'NASA_API_KEY',
          defaultValue: 'DEMO_KEY',
        ),
      );

  // Comprueba si se utiliza la clave de demostración.
  bool get usaClaveDemo => nasa == 'DEMO_KEY';

  // Verifica que exista una clave.
  void validar() {
    if (nasa.trim().isEmpty) {
      throw const ClaveFaltanteException('NASA_API_KEY');
    }
  }

  // Evita mostrar la clave completa.
  @override
  String toString() =>
      'ConfigClaves(nasa: ${_ocultar(nasa)})';

  static String _ocultar(String clave) {
    if (clave.length <= 4) {
      return '****';
    }

    return '${clave.substring(0, 2)}***${clave.substring(clave.length - 2)}';
  }
}
