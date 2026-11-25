import 'package:material_ui/material_ui.dart';

/// Compartilha a restauração iniciada no ponto de entrada com a Splash.
class StartupService {
  StartupService._();

  // Permite testar telas isoladas mesmo sem passar pelo main do aplicativo.
  static Future<void> initialization = Future<void>.value();
  static bool isReady = true;
  static Object? error;

  static Future<void> Function()? _initializer;

  static Future<void> initialize(Future<void> Function() initializer) {
    _initializer = initializer;
    return retry();
  }

  static Future<void> retry() async {
    final initializer = _initializer;
    if (initializer == null) {
      throw StateError('A inicialização do aplicativo não foi configurada.');
    }

    isReady = false;
    error = null;
    initialization = _run(initializer);
    await initialization;
  }

  static Future<void> _run(Future<void> Function() initializer) async {
    try {
      await initializer();
      isReady = true;
    } catch (exception, stackTrace) {
      error = exception;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: exception,
          stack: stackTrace,
          library: 'AlugaPlay startup',
          context: ErrorDescription('while restoring local app data'),
        ),
      );
    }
  }
}
