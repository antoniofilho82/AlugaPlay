/// Compartilha a restauração iniciada no ponto de entrada com a Splash.
class StartupService {
  StartupService._();

  // Valores padrão mantêm telas isoladas funcionais fora do ponto de entrada.
  static Future<void> initialization = Future<void>.value();
  static bool isReady = true;
}
