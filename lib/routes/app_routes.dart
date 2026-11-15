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

  /// Tela apresentada ao iniciar o aplicativo.
  static const String splash = '/';

  /// Entrada demonstrativa antes de acessar o catálogo.
  static const String login = '/login';

  /// Vitrine principal de produtos e abas da aplicação.
  static const String home = '/home';

  /// Detalhes do produto, recebido pelo argumento da navegação.
  static const String productDetails = '/product-details';

  /// Solicitação de aluguel do produto recebido em `arguments`.
  static const String rental = '/rental';

  /// Associa cada caminho à tela que deve ser construída pelo navegador.
  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    home: (_) => const HomeScreen(),
    productDetails: (_) => const ProductDetailsScreen(),
    rental: (_) => const RentalScreen(),
  };
}
