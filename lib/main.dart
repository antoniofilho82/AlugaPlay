import 'package:alugaplay/app/app.dart';
import 'package:material_ui/material_ui.dart';

import 'models/rental.dart';
import 'services/local_auth_service.dart';
import 'services/local_storage_service.dart';
import 'services/startup_service.dart';

// Inicia a restauração local antes do primeiro frame e compartilha seu progresso
// com a Splash, sem bloquear a execução inicial do aplicativo.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  StartupService.initialize(_initializeLocalData);
  runApp(const AlugaPlayApp());
}

Future<void> _initializeLocalData() async {
  await LocalStorageService.init();
  await LocalAuthService.restoreFromStorage();
  await Rental.restoreFromStorage();
}
