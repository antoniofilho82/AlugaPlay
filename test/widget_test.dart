import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alugaplay/app/app.dart';
import 'package:alugaplay/data/mock_products.dart';
import 'package:alugaplay/models/rental.dart';
import 'package:alugaplay/models/user_profile.dart';
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

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StartupService.isReady = true;
    StartupService.initialization = Future<void>.value();
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
    AppTheme.themeModeNotifier.value = ThemeMode.system;
    Rental.localRequests.clear();
    await LocalAuthService.clearAllForTest();
  });

  testWidgets('Splash screen navigates to login after its display interval', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlugaPlayApp());

    expect(find.bySemanticsLabel('AlugaPlay'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/splash_bg.jpeg')),
      findsNothing,
    );
    expect(find.byIcon(Icons.sports_esports_rounded), findsOneWidget);
    final brandTitle = find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText() == 'AlugaPlay',
    );
    expect(brandTitle, findsOneWidget);
    expect(find.text('Consoles, jogos e pacotes'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final progressPosition = tester.widget<Positioned>(
      find.ancestor(
        of: find.byType(LinearProgressIndicator),
        matching: find.byType(Positioned),
      ),
    );
    expect(progressPosition.bottom, 44);
    expect(
      tester.getSize(find.byKey(const ValueKey('splash-progress-container'))),
      const Size(172, 5),
    );
    final progressBar = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('splash-progress')),
    );
    expect(progressBar.minHeight, 5);
    expect(progressBar.backgroundColor, Colors.transparent);
    expect(
      tester
          .widget<ColoredBox>(
            find.byKey(const ValueKey('splash-progress-track')),
          )
          .color,
      const Color(0xFF1A2E23),
    );
    expect(progressBar.value, 0);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 400));
    final progress = tester
        .widget<LinearProgressIndicator>(
          find.byKey(const ValueKey('splash-progress')),
        )
        .value!;
    expect(progress, greaterThan(0));
    expect(progress, lessThan(1));
    expect(find.bySemanticsLabel('AlugaPlay'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1050));
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('splash-progress')),
          )
          .value,
      1,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Entrar na plataforma'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
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

    await tester.tap(find.byKey(const ValueKey('quick-filter-button')));
    await tester.pumpAndSettle();

    expect(find.text('Console / Plataforma'), findsOneWidget);
    expect(find.text('Estilo / Tipo de jogo'), findsOneWidget);
    final selectedPlatformChip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('quick-platform-Todas')),
    );
    expect(selectedPlatformChip.selected, isTrue);
    expect(selectedPlatformChip.selectedColor, const Color(0xFF16A34A));
    expect(selectedPlatformChip.labelStyle?.color, Colors.white);
    expect(selectedPlatformChip.labelStyle?.fontWeight, FontWeight.w600);

    final unselectedStyleChip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('quick-style-Ação')),
    );
    expect(unselectedStyleChip.selected, isFalse);
    expect(unselectedStyleChip.backgroundColor, const Color(0xFF14241B));
    expect(unselectedStyleChip.side?.color, const Color(0xFF2C4A39));
    expect(unselectedStyleChip.labelStyle?.color, const Color(0xFFECF5EF));
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
      Colors.white,
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

  test('light theme uses soft surfaces and readable text colors', () {
    final theme = AppTheme.lightTheme;

    expect(theme.scaffoldBackgroundColor, const Color(0xFFE3ECE6));
    expect(theme.colorScheme.surface, const Color(0xFFE3ECE6));
    expect(theme.cardTheme.color, const Color(0xFFEEF4F0));
    expect(theme.inputDecorationTheme.fillColor, const Color(0xFFEEF4F0));
    expect(theme.colorScheme.outline, const Color(0xFFC8D8CE));
    expect(theme.colorScheme.onSurface, const Color(0xFF233029));
    expect(theme.colorScheme.onSurfaceVariant, const Color(0xFF52645A));
    expect(theme.colorScheme.primary, const Color(0xFF2E8B57));
    expect(theme.colorScheme.secondary, const Color(0xFF389E68));
    expect(theme.colorScheme.primaryContainer, const Color(0xFFD7E7DD));
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
    await tester.tap(find.text('Criar nova conta'));
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

  // Os campos operacionais são testados no snapshot; o formulário atual não os coleta.
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
