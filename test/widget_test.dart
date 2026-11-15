// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alugaplay/app/app.dart';
import 'package:alugaplay/models/rental.dart';
import 'package:alugaplay/models/user_profile.dart';
import 'package:alugaplay/screens/home/home_screen.dart';
import 'package:alugaplay/screens/product_details/product_details_screen.dart';
import 'package:alugaplay/theme/app_theme.dart';

void main() {
  // Cada caso começa com sessão e lista de aluguéis independentes.
  setUp(() {
    AppTheme.themeModeNotifier.value = ThemeMode.system;
    Rental.localRequests.clear();
    UserProfile.reset();
  });
  // A limpeza final evita que um fluxo incompleto contamine os casos seguintes.
  tearDown(() {
    AppTheme.themeModeNotifier.value = ThemeMode.system;
    Rental.localRequests.clear();
    UserProfile.reset();
  });

  // Confere o redirecionamento automático da apresentação para a tela de entrada.
  testWidgets('Splash screen navigates to login after its display interval', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());

    expect(find.byIcon(Icons.sports_esports_rounded), findsOneWidget);
    expect(find.text('Consoles, jogos e pacotes'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('Entrar na plataforma'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  // Exercita seleção de produto, solicitação, retorno à Home e cancelamento.
  testWidgets('customer can rent a selected catalog product end to end', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    const productName = "Marvel's Spider-Man 2";
    final productFinder = find.text(productName);
    await tester.scrollUntilVisible(
      productFinder,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(productFinder);
    await tester.pumpAndSettle();

    expect(find.text(productName), findsOneWidget);
    expect(find.text('Jogos'), findsOneWidget);
    expect(find.text('PlayStation 5'), findsOneWidget);
    expect(
      find.text(
        'Jogo físico de ação e aventura ambientado no universo do Homem-Aranha, '
        'para PlayStation 5.',
      ),
      findsOneWidget,
    );
    expect(find.text('R\$ 24,90'), findsOneWidget);

    await tester.tap(find.text('Solicitar Aluguel'));
    await tester.pumpAndSettle();

    expect(find.text(productName), findsOneWidget);
    expect(find.text('3 dia(s)'), findsOneWidget);
    expect(find.text('R\$ 74,70'), findsOneWidget);

    await tester.tap(find.text('Confirmar Solicitação'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitação registrada'), findsOneWidget);
    expect(find.text(productName), findsNWidgets(2));
    expect(find.text('3 dia(s)'), findsNWidgets(2));
    expect(find.text('R\$ 74,70'), findsNWidgets(2));

    await tester.tap(find.text('Voltar ao Catálogo'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(Rental.localRequests, hasLength(1));
    expect(Rental.localRequests.single.product.id, 'spider-man-2');
    expect(Rental.localRequests.single.totalDays, 3);
    expect(Rental.localRequests.single.estimatedTotal, closeTo(74.7, 0.001));

    await tester.tap(find.text('Meus aluguéis'));
    await tester.pumpAndSettle();
    expect(find.text(productName), findsOneWidget);
    expect(find.text('1 solicitação'), findsOneWidget);

    await tester.ensureVisible(find.text('Cancelar solicitação'));
    await tester.tap(find.text('Cancelar solicitação'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma solicitação registrada'), findsOneWidget);
    expect(Rental.localRequests, isEmpty);
  });

  // Garante que a busca funciona em 360 × 800 sem provocar overflow.
  testWidgets(
    'home search filters products on a compact screen without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const AlugaPlayApp());
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Tears of the Kingdom',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('The Legend of Zelda: Tears of the Kingdom'),
        findsOneWidget,
      );
      expect(find.text('1 item'), findsOneWidget);
      expect(find.text("Marvel's Spider-Man 2"), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  // Verifica que o e-mail chega ao perfil e que sair encerra a sessão.
  testWidgets('login email appears in profile and sign out returns to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'lucas@alugaplay.com');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('lucas@alugaplay.com'), findsOneWidget);
    expect(find.text('Lucas'), findsOneWidget);

    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar na plataforma'), findsOneWidget);
    expect(UserProfile.currentUser, UserProfile.defaultProfile);
    expect(Rental.localRequests, isEmpty);
  });

  // Alterna o modo ativo em runtime e confirma que o MaterialApp acompanha o notifier.
  testWidgets('user can switch between light and dark themes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    final homeContext = tester.element(find.byType(HomeScreen));
    final initialBrightness = Theme.of(homeContext).brightness;
    AppTheme.toggleTheme(initialBrightness);
    await tester.pumpAndSettle();

    final switchedBrightness = Theme.of(tester.element(find.byType(HomeScreen)))
        .brightness;
    expect(switchedBrightness, isNot(initialBrightness));
    expect(
      AppTheme.themeModeNotifier.value,
      switchedBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    );

    AppTheme.toggleTheme(switchedBrightness);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(HomeScreen))).brightness,
      initialBrightness,
    );
  });

  // O voltar percorre o histórico de abas antes de retornar ao catálogo.
  testWidgets('system back follows tab history and pops product details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Categorias').last);
    await tester.pumpAndSettle();
    expect(find.text('Explore categorias'), findsOneWidget);

    await tester.tap(find.text('Meus aluguéis').last);
    await tester.pumpAndSettle();
    expect(find.text('Meus Aluguéis'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Explore categorias'), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Olá, Jogador!'), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);

    const productName = "Marvel's Spider-Man 2";
    final productFinder = find.text(productName);
    await tester.scrollUntilVisible(
      productFinder,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(productFinder);
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
