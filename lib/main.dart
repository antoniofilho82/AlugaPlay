import 'package:alugaplay/app/app.dart';
import 'package:material_ui/material_ui.dart';

import 'models/rental.dart';
import 'services/local_auth_service.dart';
import 'services/local_storage_service.dart';
import 'services/startup_service.dart';

// Inicia a restauração antes do primeiro frame sem aguardar o armazenamento.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  StartupService.isReady = false;
  StartupService.initialization = _initializeLocalData().then((_) {
    StartupService.isReady = true;
  });
  runApp(const AlugaPlayApp());
}

Future<void> _initializeLocalData() async {
  await LocalStorageService.init();
  await LocalAuthService.restoreFromStorage();
  await Rental.restoreFromStorage();
}
