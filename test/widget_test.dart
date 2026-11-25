import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alugaplay/app/app.dart';
import 'package:alugaplay/components/alugaplay_logo.dart';
import 'package:alugaplay/components/product_card.dart';
import 'package:alugaplay/data/mock_products.dart';
import 'package:alugaplay/models/rental.dart';
import 'package:alugaplay/models/user_profile.dart';
import 'package:alugaplay/routes/app_routes.dart';
import 'package:alugaplay/screens/home/home_screen.dart';
import 'package:alugaplay/screens/login/forgot_password_screen.dart';
import 'package:alugaplay/screens/login/login_screen.dart';
import 'package:alugaplay/screens/login/register_screen.dart';
import 'package:alugaplay/screens/product_details/product_details_screen.dart';
import 'package:alugaplay/services/local_auth_service.dart';
import 'package:alugaplay/services/local_storage_service.dart';
import 'package:alugaplay/services/startup_service.dart';
import 'package:alugaplay/theme/app_theme.dart';

Future<void> _signIn(
  WidgetTester tester, {
  String password = 'senha123',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('login-email')),
    'lucas@alugaplay.com',
  );
  await tester.enterText(
    find.byKey(const ValueKey('login-password')),
    password,
  );
  await tester.ensureVisible(find.text('Entrar'));
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

void _expectAlugaPlayWordmark(WidgetTester tester) {
  expect(find.byType(AlugaPlayWordmark), findsOneWidget);
  final brightness = Theme.of(tester.element(find.byType(AlugaPlayWordmark)))
      .brightness;
  final isLight = brightness == Brightness.light;
  final fill = tester.widget<RichText>(
    find.byKey(const ValueKey('alugaplay-wordmark-fill')),
  );
  final fillParts = (fill.text as TextSpan).children!;
  expect((fillParts[0] as TextSpan).style?.color, AppTheme.gold);
  expect((fillParts[1] as TextSpan).style?.color, const Color(0xFFF8FAFC));

  final outline = tester.widget<RichText>(
    find.byKey(const ValueKey('alugaplay-wordmark-outline')),
  );
  final outlineStyle = (outline.text as TextSpan).style!;
  expect(outlineStyle.foreground?.style, PaintingStyle.stroke);
  final titleFontSize = outlineStyle.fontSize!;
  expect(
    outlineStyle.foreground?.color.toARGB32(),
    isLight ? 0xFF1E3A8A : 0xFF050811,
  );
  expect(
    outlineStyle.foreground?.strokeWidth,
    closeTo(titleFontSize * (isLight ? 0.055 : 0.08), 0.001),
  );
  expect(
    outlineStyle.shadows?.any(
      (shadow) =>
          shadow.color == AppTheme.blue.withValues(alpha: isLight ? 0.58 : 0.9),
    ),
    isTrue,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StartupService.isReady = true;
    StartupService.initialization = Future<void>.value();
    StartupService.error = null;
    await LocalStorageService.init();
    AppTheme.themeModeNotifier.value = ThemeMode.system;
    Rental.localRequests.clear();
    await LocalAuthService.clearAllForTest();
    await LocalAuthService.register(
      name: 'Lucas',
      email: 'lucas@alugaplay.com',
      phone: '(86) 99999-0000',
      city: 'Teresina, PI',
      password: 'senha123',
      remember: false,
    );
    await LocalAuthService.logout();
  });
  tearDown(() async {
    StartupService.isReady = true;
    StartupService.initialization = Future<void>.value();
    StartupService.error = null;
    AppTheme.themeModeNotifier.value = ThemeMode.system;
    Rental.localRequests.clear();
    await LocalAuthService.clearAllForTest();
  });

  testWidgets('Splash stays visible before routing to login', (
    WidgetTester tester,
  ) async {
    final startup = Completer<void>();
    StartupService.isReady = false;
    StartupService.initialization = startup.future;
    await tester.pumpWidget(const AlugaPlayApp());

    final splashAsset = await rootBundle.load(
      'assets/images/splash_screen.png',
    );
    expect(splashAsset.lengthInBytes, greaterThan(0));
    expect(find.bySemanticsLabel('AlugaPlay'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/splash_screen.png')),
      findsOneWidget,
    );
    expect(find.byType(AlugaPlayWordmark), findsNothing);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).initialRoute,
      AppRoutes.splash,
    );
    final splashImage = tester.widget<Image>(
      find.image(const AssetImage('assets/images/splash_screen.png')),
    );
    expect(splashImage.fit, BoxFit.cover);
    expect(splashImage.filterQuality, FilterQuality.high);
    final splashImageSize = tester.getSize(
      find.image(const AssetImage('assets/images/splash_screen.png')),
    );
    expect(splashImageSize.width, greaterThan(0));
    expect(splashImageSize.height, greaterThan(0));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      const Color(0xFF000000),
    );
    expect(find.byKey(const ValueKey('splash-progress')), findsOneWidget);
    expect(find.text('Consoles, jogos e pacotes'), findsNothing);
    expect(find.text('Entrar na plataforma'), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('AlugaPlay'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    startup.complete();
    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.bySemanticsLabel('AlugaPlay'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Entrar na plataforma'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    StartupService.isReady = true;
    StartupService.initialization = Future<void>.value();
    await tester.pumpWidget(const AlugaPlayApp());
    expect(find.bySemanticsLabel('AlugaPlay'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('AlugaPlay'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Splash waits for local restoration before selecting a route', (
    WidgetTester tester,
  ) async {
    final startup = Completer<void>();
    StartupService.isReady = false;
    StartupService.initialization = startup.future;
    await LocalAuthService.login(
      'lucas@alugaplay.com',
      'senha123',
      remember: true,
    );

    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.bySemanticsLabel('AlugaPlay'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);

    startup.complete();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('Splash reports startup failure and retries restoration', (
    WidgetTester tester,
  ) async {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (_) {};
    var attempts = 0;
    StartupService.initialize(() async {
      attempts++;
      if (attempts == 1) throw StateError('Local data could not be restored');
    });

    try {
      await tester.pumpWidget(const AlugaPlayApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível restaurar os dados locais.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('splash-retry')), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(StartupService.isReady, isFalse);

      await tester.tap(find.byKey(const ValueKey('splash-retry')));
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(StartupService.isReady, isTrue);
    } finally {
      FlutterError.onError = previousErrorHandler;
    }
  });

  testWidgets('customer can rent a selected catalog product end to end', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    await _signIn(tester);
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

    await LocalAuthService.updateCurrentUserProfile(
      name: 'Lucas',
      phone: '(86) 99999-0000',
      cpf: '',
      profileImagePath: UserProfile.currentUser.profileImagePath,
      city: 'Teresina, PI',
      address: 'Rua das Flores, 10 • Centro • Teresina/PI • 64000-000',
    );
    UserProfile.defaultDeliveryMethod = 'Entrega Delivery';
    await tester.tap(find.text('Solicitar Aluguel'));
    await tester.pumpAndSettle();

    expect(find.text(productName), findsOneWidget);
    expect(find.text('3 dia(s)'), findsOneWidget);
    expect(find.text('R\$ 74,70'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('rental-delivery-address')),
          )
          .controller!
          .text,
      'Rua das Flores, 10 • Centro • Teresina/PI • 64000-000',
    );

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
    expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    expect(find.text(productName), findsOneWidget);
    expect(find.text('1 solicitação'), findsOneWidget);

    await tester.ensureVisible(find.text('Cancelar solicitação'));
    await tester.tap(find.text('Cancelar solicitação'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma solicitação registrada'), findsOneWidget);
    expect(Rental.localRequests, isEmpty);
  });

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
      await _signIn(tester);

      _expectAlugaPlayWordmark(tester);
      expect(find.byKey(const ValueKey('home-brand-logo')), findsNothing);
      expect(find.text('Olá, Jogador!'), findsNothing);
      expect(find.text('Sua próxima aventura começa aqui.'), findsNothing);
      final productCard = find.byType(ProductCard).first;
      final card = tester.widget<Card>(
        find.descendant(of: productCard, matching: find.byType(Card)),
      );
      expect(
        card.color,
        Theme.of(tester.element(productCard)).colorScheme.surface,
      );

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

  testWidgets('quick filters combine platform and game style and can clear', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    await _signIn(tester);

    final colorScheme = Theme.of(tester.element(find.byType(HomeScreen)))
        .colorScheme;
    await tester.tap(find.byKey(const ValueKey('quick-filter-button')));
    await tester.pumpAndSettle();

    expect(find.text('Console / Plataforma'), findsOneWidget);
    expect(find.text('Estilo / Tipo de jogo'), findsOneWidget);
    final selectedPlatformChip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('quick-platform-Todas')),
    );
    expect(selectedPlatformChip.selected, isTrue);
    expect(selectedPlatformChip.selectedColor, colorScheme.primary);
    expect(
      selectedPlatformChip.backgroundColor,
      colorScheme.surfaceContainerHighest,
    );
    expect(selectedPlatformChip.labelStyle?.color, colorScheme.onPrimary);
    expect(selectedPlatformChip.labelStyle?.fontWeight, FontWeight.w600);

    final unselectedStyleChip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('quick-style-Ação')),
    );
    expect(unselectedStyleChip.selected, isFalse);
    expect(
      unselectedStyleChip.backgroundColor,
      colorScheme.surfaceContainerHighest,
    );
    expect(unselectedStyleChip.side?.color, colorScheme.outlineVariant);
    expect(unselectedStyleChip.labelStyle?.color, colorScheme.onSurface);
    expect(unselectedStyleChip.labelStyle?.fontWeight, FontWeight.w500);

    await tester.tap(
      find.byKey(const ValueKey('quick-platform-PlayStation 5')),
    );
    await tester.tap(find.byKey(const ValueKey('quick-style-Ação')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('quick-platform-PlayStation 5')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('quick-style-Ação')))
          .labelStyle
          ?.color,
      colorScheme.onPrimary,
    );
    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('quick-platform-Todas')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('quick-style-Todos')))
          .selected,
      isTrue,
    );
    await tester.tap(
      find.byKey(const ValueKey('quick-platform-PlayStation 5')),
    );
    await tester.tap(find.byKey(const ValueKey('quick-style-Ação')));
    await tester.tap(find.text('Aplicar filtro'));
    await tester.pumpAndSettle();

    expect(find.text('PlayStation 5 · Ação'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text("Marvel's Spider-Man 2"),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("Marvel's Spider-Man 2"), findsOneWidget);

    await tester.ensureVisible(find.text('Limpar filtros'));
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('PlayStation 5 · Ação'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('The Legend of Zelda: Tears of the Kingdom'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('The Legend of Zelda: Tears of the Kingdom'),
      findsOneWidget,
    );
  });

  testWidgets('login email appears in profile and sign out returns to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    await _signIn(tester);

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

  testWidgets('user can switch between light and dark themes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    await _signIn(tester);

    final homeContext = tester.element(find.byType(HomeScreen));
    final initialBrightness = Theme.of(homeContext).brightness;
    AppTheme.toggleTheme(initialBrightness);
    await tester.pumpAndSettle();

    final switchedBrightness = Theme.of(tester.element(find.byType(HomeScreen)))
        .brightness;
    expect(switchedBrightness, isNot(initialBrightness));
    _expectAlugaPlayWordmark(tester);
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
    _expectAlugaPlayWordmark(tester);
  });

  test('light theme uses crisp surfaces and readable blue-gold colors', () {
    final lightTheme = AppTheme.lightTheme;
    final darkTheme = AppTheme.darkTheme;

    expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
    expect(lightTheme.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(lightTheme.cardTheme.color, const Color(0xFFFFFFFF));
    expect(lightTheme.inputDecorationTheme.fillColor, const Color(0xFFEFF6FF));
    expect(
      lightTheme.colorScheme.surfaceContainerHighest,
      const Color(0xFFEFF6FF),
    );
    expect(lightTheme.colorScheme.outline, const Color(0xFFCBD5E1));
    expect(lightTheme.colorScheme.onSurface, const Color(0xFF0F172A));
    expect(lightTheme.colorScheme.onSurfaceVariant, const Color(0xFF334155));
    expect(lightTheme.colorScheme.primary, const Color(0xFF1D4ED8));
    expect(lightTheme.colorScheme.secondary, const Color(0xFF1D4ED8));
    expect(lightTheme.colorScheme.onSecondary, const Color(0xFF050811));
    expect(lightTheme.colorScheme.secondaryContainer, const Color(0xFFDBEAFE));
    expect(
      lightTheme.colorScheme.onSecondaryContainer,
      const Color(0xFF1E3A8A),
    );
    expect(lightTheme.colorScheme.tertiary, const Color(0xFF1D4ED8));
    expect(lightTheme.colorScheme.primaryContainer, const Color(0xFFEFF6FF));
    expect(AppTheme.heroBannerGradient(Brightness.light).colors, const [
      Color(0xFFEFF6FF),
      Color(0xFFF8FAFC),
      Color(0xFFFFFFFF),
    ]);

    expect(darkTheme.colorScheme.primary, const Color(0xFF2563EB));
    expect(darkTheme.colorScheme.secondary, const Color(0xFFFACC15));
    expect(darkTheme.colorScheme.onSecondary, const Color(0xFF050811));
    expect(darkTheme.colorScheme.secondaryContainer, const Color(0xFF332B10));

    for (final theme in [lightTheme, darkTheme]) {
      expect(theme.navigationBarTheme.indicatorColor, Colors.transparent);
      for (final isSelected in [false, true]) {
        final states = isSelected ? {WidgetState.selected} : <WidgetState>{};
        final isDark = theme.brightness == Brightness.dark;
        expect(
          theme.navigationBarTheme.iconTheme?.resolve(states)?.color,
          isDark || isSelected
              ? theme.colorScheme.secondary
              : theme.colorScheme.onSurfaceVariant,
        );
        expect(
          theme.navigationBarTheme.labelTextStyle?.resolve(states)?.color,
          isDark
              ? theme.colorScheme.secondary
              : isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        );
      }
    }
  });

  testWidgets('system back follows tab history and pops product details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    await _signIn(tester);

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
    _expectAlugaPlayWordmark(tester);
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

  testWidgets('profile edits player settings and clears rental history', (
    WidgetTester tester,
  ) async {
    final startDate = DateTime.now().add(const Duration(days: 1));
    Rental.localRequests.add(
      Rental(
        id: 'profile-settings-test',
        product: mockProducts.first,
        startDate: startDate,
        endDate: startDate.add(const Duration(days: 3)),
        totalDays: 3,
        estimatedTotal: 50,
        notes: '',
      ),
    );

    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    await _signIn(tester);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Preferências'), findsOneWidget);
    expect(find.text('Locação'), findsOneWidget);
    expect(find.text('Conta e Suporte'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-dark-mode')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-notifications')), findsOneWidget);
    await tester.ensureVisible(find.text('Sair da conta'));
    expect(find.text('Sair da conta'), findsOneWidget);

    await tester.ensureVisible(find.text('Editar'));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('profile-name')), 'Alex');
    await tester.enterText(
      find.byKey(const ValueKey('profile-phone')),
      '(11) 98888-7777',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-cpf')),
      '529.982.247-25',
    );
    await tester.ensureVisible(find.text('Salvar dados'));
    await tester.tap(find.text('Salvar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Alex'), findsOneWidget);
    expect(UserProfile.currentUser.phone, '(11) 98888-7777');
    expect(UserProfile.currentUser.cpf, '529.982.247-25');

    await tester.ensureVisible(find.text('Modalidade padrão'));
    await tester.tap(find.text('Modalidade padrão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrega Delivery'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Duração padrão'));
    await tester.tap(find.text('Duração padrão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 dias'));
    await tester.pumpAndSettle();
    expect(UserProfile.defaultDeliveryMethod, 'Entrega Delivery');
    expect(UserProfile.defaultRentalDays, 7);

    await tester.ensureVisible(find.text('Endereço de entrega'));
    await tester.tap(find.text('Endereço de entrega'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('delivery-street')),
      'Rua das Flores, 10',
    );
    await tester.enterText(
      find.byKey(const ValueKey('delivery-neighborhood')),
      'Centro',
    );
    await tester.enterText(
      find.byKey(const ValueKey('delivery-city')),
      'São Paulo, SP',
    );
    await tester.enterText(
      find.byKey(const ValueKey('delivery-zip')),
      '64000-000',
    );
    await tester.ensureVisible(find.text('Salvar endereço'));
    await tester.tap(find.text('Salvar endereço'));
    await tester.pumpAndSettle();
    expect(
      UserProfile.currentUser.address,
      'Rua das Flores, 10 • Centro • São Paulo, SP • 64000-000',
    );

    await tester.ensureVisible(find.text('Limpar histórico de pedidos'));
    await tester.tap(find.text('Limpar histórico de pedidos'));
    await tester.pumpAndSettle();
    expect(find.text('Limpar histórico de pedidos?'), findsOneWidget);
    await tester.tap(find.text('Limpar pedidos'));
    await tester.pumpAndSettle();
    expect(Rental.localRequests, isEmpty);
  });

  testWidgets('profile validates CPF and allows selecting and removing photo', (
    WidgetTester tester,
  ) async {
    await LocalAuthService.login(
      'lucas@alugaplay.com',
      'senha123',
      remember: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(profileImagePicker: () async => '/profile-photo.png'),
      ),
    );
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('profile-cpf')),
      '111.111.111-11',
    );
    await tester.ensureVisible(find.text('Salvar dados'));
    await tester.tap(find.text('Salvar dados'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um CPF válido.'), findsOneWidget);
    expect(UserProfile.currentUser.cpf, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('profile-cpf')),
      '529.982.247-25',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('choose-profile-photo')),
    );
    await tester.tap(find.byKey(const ValueKey('choose-profile-photo')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar dados'));
    await tester.tap(find.text('Salvar dados'));
    await tester.pumpAndSettle();
    expect(UserProfile.currentUser.cpf, '529.982.247-25');
    expect(UserProfile.currentUser.profileImagePath, '/profile-photo.png');

    await tester.ensureVisible(find.text('Editar'));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('remove-profile-photo')),
    );
    await tester.tap(find.byKey(const ValueKey('remove-profile-photo')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar dados'));
    await tester.tap(find.text('Salvar dados'));
    await tester.pumpAndSettle();
    expect(UserProfile.currentUser.profileImagePath, isNull);
  });

  testWidgets('local login blocks accounts that do not authenticate', (
    WidgetTester tester,
  ) async {
    await LocalAuthService.clearAllForTest();
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    _expectAlugaPlayWordmark(tester);

    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'nao.cadastrado@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'senha123',
    );
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(
      find.text(LocalAuthService.invalidCredentialsMessage),
      findsOneWidget,
    );
    expect(find.byType(HomeScreen), findsNothing);

    await LocalAuthService.register(
      name: 'Teste Local',
      email: 'nao.cadastrado@example.com',
      phone: '(86) 99999-0000',
      password: 'senha123',
      remember: false,
    );
    await LocalAuthService.logout();
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'senhaerrada',
    );
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(
      find.text(LocalAuthService.invalidCredentialsMessage),
      findsOneWidget,
    );
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('new account registers and opens the authenticated profile', (
    WidgetTester tester,
  ) async {
    await LocalAuthService.clearAllForTest();
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Criar nova conta'));
    final registerFooter = find.byKey(const ValueKey('register-footer-line'));
    expect(
      tester.getCenter(registerFooter).dx,
      closeTo(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
        1,
      ),
    );
    final registerLink = find.byKey(const ValueKey('register-account-link'));
    final registerLinkWidget = tester.widget<InkWell>(registerLink);
    expect(registerLinkWidget.onHighlightChanged, isNotNull);
    expect(
      registerLinkWidget.splashColor,
      AppTheme.blueAccent.withValues(alpha: 0.28),
    );
    expect(
      registerLinkWidget.highlightColor,
      AppTheme.gold.withValues(alpha: 0.22),
    );
    expect(registerLinkWidget.mouseCursor, SystemMouseCursors.click);

    final gesture = await tester.startGesture(tester.getCenter(registerLink));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<Text>(find.text('Criar nova conta')).style?.color,
      AppTheme.gold,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('register-city')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('register-name')),
      'Marina Gamer',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'marina@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-phone')),
      '(86) 98888-7777',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password')),
      'senhaNova123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm-password')),
      'senhaNova123',
    );
    await tester.ensureVisible(find.text('Criar Conta'));
    await tester.tap(find.text('Criar Conta'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(LocalAuthService.currentUser?.email, 'marina@example.com');
    expect(UserProfile.currentUser.city, isEmpty);
    expect(UserProfile.currentUser.address, isEmpty);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Marina Gamer'), findsOneWidget);
    final initial = find.text('M');
    expect(initial, findsOneWidget);
    expect(
      find.ancestor(of: initial, matching: find.byType(ClipOval)),
      findsOneWidget,
    );
    final initialText = tester.widget<Text>(initial);
    expect(initialText.style?.color, Colors.white);
    expect(initialText.style?.fontSize, 24);
    expect(initialText.style?.fontWeight, FontWeight.bold);
  });

  // Os campos avançados são testados no modelo/snapshot; o formulário atual não os coleta.
  test(
    'local storage restores account, preferences, and rental details',
    () async {
      await LocalAuthService.clearAllForTest();
      await LocalAuthService.register(
        name: 'Marina Gamer',
        email: 'marina@example.com',
        phone: '(86) 98888-7777',
        password: 'senhaNova123',
      );
      await LocalAuthService.updateCurrentUserProfile(
        name: 'Marina Gamer',
        phone: '(86) 98888-7777',
        cpf: '',
        profileImagePath: '/marina-profile.png',
        city: 'Teresina, PI',
        address: 'Rua Gamer, 10',
      );
      UserProfile.defaultDeliveryMethod = 'Entrega Delivery';
      UserProfile.defaultRentalDays = 7;
      UserProfile.favoritePlatform = 'PlayStation 5';
      UserProfile.notifyReturnReminder = false;
      UserProfile.notifyNewReleases = false;
      AppTheme.themeModeNotifier.value = ThemeMode.dark;
      await LocalAuthService.persistPreferences();

      final startDate = DateTime(2026, 11, 21);
      Rental.localRequests.add(
        Rental(
          id: 'persistent-rental',
          product: mockProducts.first,
          startDate: startDate,
          endDate: startDate.add(const Duration(days: 3)),
          totalDays: 3,
          estimatedTotal: 269.7,
          notes: 'Retirada no período da tarde',
          pin: '1234',
          serialNumber: 'SN-ALUGAPLAY-001',
          checklist: const ['Console', 'Controle', 'Cabos'],
          deposit: 150,
          paymentMethod: 'Pix',
          termsAccepted: true,
          deliveryMethod: 'Entrega Delivery',
          deliveryAddress: 'Rua Gamer, 10',
        ),
      );
      await LocalStorageService.saveRentals(
        Rental.localRequests.map((rental) => rental.toJson()).toList(),
      );

      LocalAuthService.clearInMemoryForTest();
      Rental.localRequests.clear();
      AppTheme.themeModeNotifier.value = ThemeMode.system;
      await LocalAuthService.restoreFromStorage();
      await Rental.restoreFromStorage();

      expect(LocalAuthService.currentUser?.email, 'marina@example.com');
      expect(LocalAuthService.rememberedEmail, 'marina@example.com');
      expect(LocalAuthService.shouldAutoLogin, isTrue);
      expect(
        LocalStorageService.loadSession()!.containsKey('rememberedPassword'),
        isFalse,
      );
      expect(UserProfile.currentUser.profileImagePath, '/marina-profile.png');
      expect(UserProfile.defaultDeliveryMethod, 'Entrega Delivery');
      expect(UserProfile.defaultRentalDays, 7);
      expect(UserProfile.favoritePlatform, 'PlayStation 5');
      expect(UserProfile.notifyReturnReminder, isFalse);
      expect(AppTheme.themeModeNotifier.value, ThemeMode.dark);
      expect(Rental.localRequests, hasLength(1));
      final restoredRental = Rental.localRequests.single;
      expect(restoredRental.pin, '1234');
      expect(restoredRental.serialNumber, 'SN-ALUGAPLAY-001');
      expect(restoredRental.checklist, ['Console', 'Controle', 'Cabos']);
      expect(restoredRental.deposit, 150);
      expect(restoredRental.paymentMethod, 'Pix');
      expect(restoredRental.termsAccepted, isTrue);
      expect(restoredRental.deliveryAddress, 'Rua Gamer, 10');
    },
  );

  testWidgets('remembered login restores home and logout clears the session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'lucas@alugaplay.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'senha123',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(LocalAuthService.shouldAutoLogin, isTrue);
    final persistedSession = LocalStorageService.loadSession()!;
    expect(persistedSession['rememberAccess'], isTrue);
    expect(persistedSession['currentUserEmail'], 'lucas@alugaplay.com');
    expect(persistedSession.containsKey('rememberedPassword'), isFalse);

    LocalAuthService.clearInMemoryForTest();
    await LocalAuthService.restoreFromStorage();
    expect(LocalAuthService.shouldAutoLogin, isTrue);
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(LocalAuthService.shouldAutoLogin, isFalse);
    expect(LocalAuthService.rememberAccess, isFalse);
    expect(LocalAuthService.currentUserEmail, isNull);
    expect(LocalStorageService.loadSession(), isNull);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('login-email')))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('login-password')))
          .controller!
          .text,
      isEmpty,
    );

    LocalAuthService.clearInMemoryForTest();
    await LocalAuthService.restoreFromStorage();
    await tester.pumpWidget(const AlugaPlayApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('login-email')))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('login-password')))
          .controller!
          .text,
      isEmpty,
    );

    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('forgot-email')),
      'lucas@alugaplay.com',
    );
    await tester.tap(find.text('Verificar e-mail'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('forgot-password')),
      'senhaNova789',
    );
    await tester.enterText(
      find.byKey(const ValueKey('forgot-confirm-password')),
      'senhaNova789',
    );
    await tester.tap(find.text('Redefinir senha'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsNothing);
    expect(LocalAuthService.shouldAutoLogin, isFalse);
    await _signIn(tester, password: 'senhaNova789');
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
