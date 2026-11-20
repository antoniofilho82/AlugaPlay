import 'package:material_ui/material_ui.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

/// Reúne as configurações globais usadas por todas as telas do aplicativo.
class AlugaPlayApp extends StatelessWidget {
  const AlugaPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'AlugaPlay',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          themeAnimationDuration: Duration.zero,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
