import 'package:material_ui/material_ui.dart';

import '../screens/home/home_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/product_details/product_details_screen.dart';
import '../screens/rental/rental_screen.dart';
import '../screens/splash/splash_screen.dart';

/// Centraliza os caminhos nomeados para que a equipe não repita strings soltas.
///
/// Use estas constantes em `Navigator.pushNamed` para manter o fluxo consistente.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';

  static const String login = '/login';

  static const String home = '/home';

  static const String productDetails = '/product-details';

  static const String rental = '/rental';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    home: (_) => const HomeScreen(),
    productDetails: (_) => const ProductDetailsScreen(),
    rental: (_) => const RentalScreen(),
  };
}
