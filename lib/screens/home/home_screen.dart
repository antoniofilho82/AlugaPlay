import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../../components/category_item.dart';
import '../../components/product_card.dart';
import '../../components/primary_button.dart';
import '../../data/mock_products.dart';
import '../../models/product.dart';
import '../../models/rental.dart';
import '../../models/user_profile.dart';
import '../../routes/app_routes.dart';
import '../../services/local_auth_service.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_theme.dart';

/// Reúne o catálogo e as áreas de navegação do cliente.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.profileImagePicker});

  final Future<String?> Function()? profileImagePicker;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surface;
  Color get _accent => Theme.of(context).colorScheme.secondary;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;

  static const List<String> _categories = [
    'Todos',
    'Consoles',
    'Jogos',
    'Pacotes',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Todos': Icons.grid_view_rounded,
    'Consoles': Icons.sports_esports_rounded,
    'Jogos': Icons.videogame_asset_rounded,
    'Pacotes': Icons.card_giftcard_rounded,
  };

  final TextEditingController _searchController = TextEditingController();
  // Permite que Voltar percorra as abas visitadas antes de sair da Home.
  final List<int> _tabHistory = [];
  int _selectedTab = 0;
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  String _selectedPlatformFilter = 'Todas';
  String _selectedGameStyleFilter = 'Todos';

  static const Map<String, List<String>> _gameStyleKeywords = {
    'Ação': ['ação', 'action'],
    'Aventura': ['aventura', 'adventure'],
    'RPG': ['rpg', 'role-playing'],
    'Corrida': ['corrida', 'racing'],
    'Esportes': ['esporte', 'sports', 'futebol'],
    'Luta': ['luta', 'fighting'],
    'Estratégia': ['estratégia', 'strategy'],
    'Simulação': ['simulação', 'simulation'],
  };

  // As opções refletem os valores de plataforma presentes no catálogo.
  List<String> get _availablePlatforms => [
    'Todas',
    ...{
      for (final product in mockProducts)
        if (product.platform.trim().isNotEmpty) product.platform.trim(),
    },
  ];

  // Só oferece estilos para os quais há ao menos um jogo ou pacote compatível.
  List<String> get _availableGameStyles => [
    'Todos',
    for (final style in _gameStyleKeywords.keys)
      if (mockProducts.any(
        (product) =>
            (product.category == 'Jogos' || product.category == 'Pacotes') &&
            _productMatchesGameStyle(product, style),
      ))
        style,
  ];

  bool get _hasQuickFilters =>
      _selectedPlatformFilter != 'Todas' || _selectedGameStyleFilter != 'Todos';

  String get _quickFilterSummary => [
    if (_selectedPlatformFilter != 'Todas') _selectedPlatformFilter,
    if (_selectedGameStyleFilter != 'Todos') _selectedGameStyleFilter,
  ].join(' · ');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Categoria, console, estilo e busca são aplicados em conjunto por produto.
  List<Product> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    return mockProducts.where((product) {
      final matchesCategory =
          _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesPlatform =
          _selectedPlatformFilter == 'Todas' ||
          product.platform.toLowerCase() ==
              _selectedPlatformFilter.toLowerCase();
      final matchesGameStyle =
          _selectedGameStyleFilter == 'Todos' ||
          ((product.category == 'Jogos' || product.category == 'Pacotes') &&
              _productMatchesGameStyle(product, _selectedGameStyleFilter));
      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.platform.toLowerCase().contains(query);
      return matchesCategory &&
          matchesPlatform &&
          matchesGameStyle &&
          matchesSearch;
    }).toList();
  }

  // Classifica o texto descritivo; gênero não é um campo explícito do catálogo.
  static bool _productMatchesGameStyle(Product product, String style) {
    final keywords = _gameStyleKeywords[style];
    if (keywords == null) return false;
    final searchableText = [
      product.name,
      product.shortDescription,
      product.fullDescription,
      ...product.specs,
    ].join(' ').toLowerCase();
    return keywords.any(searchableText.contains);
  }

  // Localiza o item destacado sem assumir que sempre haverá um cadastrado.
  Product? get _featuredProduct {
    for (final product in mockProducts) {
      if (product.isFeatured) return product;
    }
    return null;
  }

  // Envia o próprio produto selecionado e atualiza dados locais ao retornar.
  Future<void> _openProduct(Product product) async {
    await Navigator.of(context)
        .pushNamed(AppRoutes.productDetails, arguments: product);
    if (!mounted) return;
    setState(() {});
  }

  // Selecionar categoria também leva o usuário de volta à vitrine principal.
  void _selectCategory(String category) {
    _navigateToTab(0);
    setState(() {
      _selectedCategory = category;
    });
  }

  /// Troca de aba e registra a origem sem repetir a mesma entrada em sequência.
  void _navigateToTab(int index) {
    if (index == _selectedTab) return;

    setState(() {
      if (_tabHistory.isEmpty || _tabHistory.last != _selectedTab) {
        _tabHistory.add(_selectedTab);
      }
      _selectedTab = index;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'Todos';
      _searchQuery = '';
      _selectedPlatformFilter = 'Todas';
      _selectedGameStyleFilter = 'Todos';
      _searchController.clear();
    });
  }

  Future<void> _openQuickFilters() async {
    // As escolhas do modal só afetam o catálogo quando o usuário aplica o par.
    var selectedPlatform = _selectedPlatformFilter;
    var selectedStyle = _selectedGameStyleFilter;
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF101A14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Filtros rápidos',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickFilterSection(
                          title: 'Console / Plataforma',
                          options: _availablePlatforms,
                          selected: selectedPlatform,
                          keyPrefix: 'quick-platform',
                          onSelected: (value) =>
                              setSheetState(() => selectedPlatform = value),
                        ),
                        const SizedBox(height: 20),
                        _buildQuickFilterSection(
                          title: 'Estilo / Tipo de jogo',
                          options: _availableGameStyles,
                          selected: selectedStyle,
                          keyPrefix: 'quick-style',
                          onSelected: (value) =>
                              setSheetState(() => selectedStyle = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setSheetState(() {
                        selectedPlatform = 'Todas';
                        selectedStyle = 'Todos';
                      }),
                      child: const Text('Limpar'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(sheetContext)
                                .pop((selectedPlatform, selectedStyle)),
                        child: const Text('Aplicar filtro'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedPlatformFilter = result.$1;
      _selectedGameStyleFilter = result.$2;
    });
  }

  Widget _buildQuickFilterSection({
    required String title,
    required List<String> options,
    required String selected,
    required String keyPrefix,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                key: ValueKey('$keyPrefix-$option'),
                label: Text(option),
                selected: selected == option,
                backgroundColor: const Color(0xFF14241B),
                selectedColor: const Color(0xFF16A34A),
                side: BorderSide(
                  color: selected == option
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF2C4A39),
                ),
                labelStyle: TextStyle(
                  color: selected == option
                      ? Colors.white
                      : const Color(0xFFECF5EF),
                  fontWeight: selected == option
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
                checkmarkColor: Colors.white,
                onSelected: (_) => onSelected(option),
              ),
          ],
        ),
      ],
    );
  }

  void _showNotificationNotice() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Você está em uma experiência demonstrativa.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surface,
        ),
      );
  }

  Future<void> _toggleTheme() async {
    AppTheme.toggleTheme(Theme.of(context).brightness);
    await LocalAuthService.persistPreferences();
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    AppTheme.themeModeNotifier.value = mode;
    await LocalAuthService.persistPreferences();
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    UserProfile.notifyReturnReminder = enabled;
    UserProfile.notifyNewReleases = enabled;
    setState(() {});
    await LocalAuthService.persistPreferences();
  }

  @override
  Widget build(BuildContext context) {
    // Preserva o estado das abas e usa Voltar para percorrer histórico e filtros.
    return PopScope(
      canPop:
          _tabHistory.isEmpty &&
          _selectedTab == 0 &&
          _searchQuery.isEmpty &&
          _selectedCategory == 'Todos' &&
          !_hasQuickFilters,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_tabHistory.isNotEmpty) {
          final previousTab = _tabHistory.removeLast();
          setState(() => _selectedTab = previousTab);
        } else if (_selectedTab != 0) {
          setState(() => _selectedTab = 0);
        } else if (_searchQuery.isNotEmpty ||
            _selectedCategory != 'Todos' ||
            _hasQuickFilters) {
          _clearFilters();
        }
      },
      child: Scaffold(
        backgroundColor: _background,
        body: IndexedStack(
          index: _selectedTab,
          children: [
            _buildHomeTab(),
            _buildCategoriesTab(),
            _buildRentalsTab(),
            _buildProfileTab(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.alphaBlend(
                  AppTheme.emeraldAccent.withValues(alpha: 0.07),
                  _surface,
                ),
                _surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              top: BorderSide(
                color: AppTheme.emeraldAccent.withValues(alpha: 0.18),
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) {
              if (index == 0 && index == _selectedTab) {
                setState(_tabHistory.clear);
                return;
              }
              _navigateToTab(index);
              if (index == 0) {
                setState(_tabHistory.clear);
              }
            },
            backgroundColor: Colors.transparent,
            indicatorColor: Theme.of(context).colorScheme.primaryContainer,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Início',
              ),
              NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category_rounded),
                label: 'Categorias',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Meus aluguéis',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final products = _filteredProducts;
    final featured = _featuredProduct;
    final showFeatured =
        _searchQuery.trim().isEmpty &&
        _selectedCategory == 'Todos' &&
        !_hasQuickFilters &&
        featured != null;
    final packages = products
        .where((product) => product.category == 'Pacotes')
        .toList();
    final showPackages =
        _searchQuery.trim().isEmpty &&
        (_selectedCategory == 'Todos' || _selectedCategory == 'Pacotes') &&
        packages.isNotEmpty;

    return SafeArea(
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -18,
                    left: -20,
                    right: -20,
                    child: SizedBox(
                      height: 180,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.topAmbientGradient(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildHeader(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildSearchField(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: _buildCategoryStrip(),
            ),
          ),
          if (showFeatured)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                child: _buildFeaturedCard(featured),
              ),
            ),
          if (showPackages)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 28),
                child: _buildPackagesSection(packages),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Catálogo Disponível',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${products.length} ${products.length == 1 ? 'item' : 'itens'}',
                    style: TextStyle(
                      color: _textPrimary.withValues(alpha: 0.62),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (products.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.separated(
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => _openProduct(product),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  children: [
                    TextSpan(
                      text: 'Aluga',
                      style: TextStyle(color: _textPrimary),
                    ),
                    TextSpan(
                      text: 'Play',
                      style: TextStyle(color: _accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Olá, Jogador!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sua próxima aventura começa aqui.',
                style: TextStyle(
                  color: _textPrimary.withValues(alpha: 0.68),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _toggleTheme,
              tooltip: Theme.of(context).brightness == Brightness.dark
                  ? 'Modo claro'
                  : 'Modo escuro',
              style: IconButton.styleFrom(
                backgroundColor: _surface,
                foregroundColor: _accent,
              ),
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
            IconButton(
              onPressed: _showNotificationNotice,
              tooltip: 'Notificações',
              style: IconButton.styleFrom(
                backgroundColor: _surface,
                foregroundColor: _accent,
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      style: TextStyle(color: _textPrimary),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar consoles, jogos ou pacotes...',
        hintStyle: TextStyle(
          color: _textPrimary.withValues(alpha: 0.52),
          fontSize: 13,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: _accent),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                tooltip: 'Limpar busca',
                icon: Icon(Icons.close_rounded, color: _accent),
              ),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _textPrimary.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _accent),
        ),
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Categorias',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('quick-filter-button'),
                onPressed: _openQuickFilters,
                tooltip: 'Filtros rápidos',
                style: IconButton.styleFrom(
                  foregroundColor: _hasQuickFilters ? Colors.white : _accent,
                  backgroundColor: _hasQuickFilters
                      ? AppTheme.emerald
                      : Colors.transparent,
                ),
                icon: const Icon(Icons.filter_alt_rounded),
              ),
            ],
          ),
        ),
        if (_hasQuickFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.emeraldAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _quickFilterSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.emeraldAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.emeraldAccent,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Limpar filtros'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return CategoryItem(
                label: category,
                icon: _categoryIcons[category]!,
                isSelected: _selectedCategory == category,
                onTap: () => _selectCategory(category),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(Product product) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.heroBannerGradient(brightness),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.emeraldAccent.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Destaque da Semana',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(product.icon, color: _accent, size: 25),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: _textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            product.shortDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _textPrimary.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text(
                '${product.formattedPrice} ${product.billingUnit}',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              PrimaryButton(
                label: 'Ver detalhes',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => _openProduct(product),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesSection(List<Product> packages) {
    // Cards horizontais agrupam os pacotes sem alterar o catálogo filtrado.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pacotes Especiais',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Combinações para aproveitar ainda mais cada partida.',
                style: TextStyle(
                  color: _textPrimary.withValues(alpha: 0.66),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 302,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: packages.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = packages[index];
              return SizedBox(
                width: 280,
                child: ProductCard(
                  product: product,
                  onTap: () => _openProduct(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    // Oferece uma saída clara quando a combinação de filtros não encontra itens.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: _accent, size: 42),
          const SizedBox(height: 12),
          Text(
            'Nenhum produto encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tente outra busca ou limpe os filtros para ver o catálogo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimary.withValues(alpha: 0.68),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Limpar filtros',
            icon: Icons.refresh_rounded,
            onPressed: _clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildRentalsTab() {
    final requests = Rental.localRequests.reversed.toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Meus Aluguéis',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: _textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${requests.length} ${requests.length == 1 ? 'solicitação' : 'solicitações'}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (requests.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyRentalsState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.separated(
                itemCount: requests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) =>
                    _buildRentalCard(requests[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyRentalsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _textPrimary.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, color: _accent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Nenhuma solicitação registrada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Suas solicitações demonstrativas aparecerão aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textPrimary.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Explorar Catálogo',
                icon: Icons.explore_rounded,
                onPressed: () => _navigateToTab(0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRentalCard(Rental rental) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(rental.product.icon, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rental.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        rental.status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Retirada: ${_formatDate(rental.startDate)} • '
            'Devolução: ${_formatDate(rental.endDate)}',
            style: TextStyle(
              color: _textPrimary.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${rental.totalDays} dia(s)',
                  style: TextStyle(
                    color: _textPrimary.withValues(alpha: 0.72),
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                _formatCurrency(rental.estimatedTotal),
                style: TextStyle(
                  color: _accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (rental.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                rental.notes,
                style: TextStyle(
                  color: _textPrimary.withValues(alpha: 0.76),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _cancelRental(rental),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Cancelar solicitação'),
              style: TextButton.styleFrom(foregroundColor: _accent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRental(Rental rental) async {
    setState(() {
      Rental.localRequests.remove(rental);
    });
    await LocalStorageService.saveRentals(
      Rental.localRequests.map((request) => request.toJson()).toList(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Solicitação removida da lista demonstrativa.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surface,
        ),
      );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String _formatCurrency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  Widget _profileAvatar(
    UserProfile profile,
    String initial, {
    double size = 54,
  }) {
    final imagePath = profile.normalizedProfileImagePath;
    return Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
      ),
      child: ClipOval(
        child: imagePath == null
            ? _buildProfileInitial(initial, size)
            : Image.file(
                File(imagePath),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildProfileInitial(initial, size),
              ),
      ),
    );
  }

  Widget _buildProfileInitial(String initial, double size) {
    // Mantém a inicial visível sobre o degradê quando não há foto utilizável.
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.emeraldAccent, AppTheme.emerald],
        ),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final profile = UserProfile.currentUser;
    final initial = profile.displayName.trim().isEmpty
        ? 'J'
        : profile.displayName.trim().substring(0, 1).toUpperCase();
    final addressSummary = profile.address.trim().isNotEmpty
        ? profile.address
        : profile.city.trim().isNotEmpty
        ? profile.city
        : 'Adicionar endereço para delivery';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.heroBannerGradient(
                  Theme.of(context).brightness,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.emeraldAccent.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  _profileAvatar(profile, initial),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          profile.displayName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textPrimary.withValues(alpha: 0.65),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _editPlayerDetails,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.emerald,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Editar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _profileSectionTitle('Preferências'),
            _buildSettingsAction(
              icon: Icons.dark_mode_outlined,
              label: 'Modo escuro',
              subtitle: 'Alternar tema escuro',
              onTap: () => _setThemeMode(
                Theme.of(context).brightness == Brightness.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              ),
              trailing: Switch(
                key: const ValueKey('profile-dark-mode'),
                value: Theme.of(context).brightness == Brightness.dark,
                activeThumbColor: AppTheme.emerald,
                onChanged: (value) =>
                    _setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
              ),
            ),
            _buildSettingsAction(
              icon: Icons.notifications_none_rounded,
              label: 'Notificações',
              subtitle: 'Alertas de devolução e novidades',
              onTap: () => _setNotificationsEnabled(
                !(UserProfile.notifyReturnReminder &&
                    UserProfile.notifyNewReleases),
              ),
              trailing: Switch(
                key: const ValueKey('profile-notifications'),
                value:
                    UserProfile.notifyReturnReminder &&
                    UserProfile.notifyNewReleases,
                activeThumbColor: AppTheme.emerald,
                onChanged: _setNotificationsEnabled,
              ),
            ),
            const SizedBox(height: 20),
            _profileSectionTitle('Locação'),
            _buildSettingsAction(
              icon: Icons.local_shipping_outlined,
              label: 'Modalidade padrão',
              subtitle: UserProfile.defaultDeliveryMethod,
              onTap: _selectDeliveryMethod,
            ),
            _buildSettingsAction(
              icon: Icons.calendar_month_outlined,
              label: 'Duração padrão',
              subtitle: UserProfile.defaultRentalDays == 1
                  ? '1 dia'
                  : '${UserProfile.defaultRentalDays} dias',
              onTap: _selectRentalDuration,
            ),
            _buildSettingsAction(
              icon: Icons.sports_esports_outlined,
              label: 'Plataforma favorita',
              subtitle: UserProfile.favoritePlatform,
              onTap: _selectFavoritePlatform,
            ),
            _buildSettingsAction(
              icon: Icons.location_on_outlined,
              label: 'Endereço de entrega',
              subtitle: addressSummary,
              onTap: _editDeliveryAddress,
            ),
            const SizedBox(height: 20),
            _profileSectionTitle('Conta e Suporte'),
            _buildSettingsAction(
              icon: Icons.receipt_long_outlined,
              label: 'Minhas solicitações de aluguel',
              subtitle:
                  '${Rental.localRequests.length} solicitações demonstrativas',
              onTap: () => _navigateToTab(2),
            ),
            _buildSettingsAction(
              icon: Icons.description_outlined,
              label: 'Termos de locação e caução',
              subtitle: 'Conservação, devolução e condições',
              onTap: _showRentalTerms,
            ),
            _buildSettingsAction(
              icon: Icons.delete_sweep_outlined,
              label: 'Limpar histórico de pedidos',
              subtitle: 'Remover solicitações desta sessão',
              onTap: _confirmClearRentalHistory,
            ),
            _buildSettingsAction(
              icon: Icons.info_outline_rounded,
              label: 'Sobre o AlugaPlay',
              subtitle: 'Versão 1.0.0 • Equipe de desenvolvimento',
              onTap: _showAbout,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair da conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: BorderSide(color: _accent.withValues(alpha: 0.65)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsAction({
    required IconData icon,
    required String label,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          margin: const EdgeInsets.only(bottom: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.emeraldAccent.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.emeraldAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary.withValues(alpha: 0.62),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(Icons.chevron_right_rounded, color: _accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sobre o AlugaPlay',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Versão 1.0.0 • Flutter / Dart\n'
            'Equipe: Antonio Moura da Costa Filho, Enzo de Melo Cordeiro '
            'e Marcus Vinicius Ferreira Lustosa',
            style: TextStyle(
              color: _textPrimary.withValues(alpha: 0.72),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: _textPrimary, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<String?> _chooseSetting({
    required String title,
    required List<String> options,
    required String selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Text(
                  title,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option),
                  trailing: selected == option
                      ? const Icon(Icons.check_rounded, color: AppTheme.emerald)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, option),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDeliveryMethod() async {
    final value = await _chooseSetting(
      title: 'Modalidade padrão',
      options: const ['Retirada na Loja', 'Entrega Delivery'],
      selected: UserProfile.defaultDeliveryMethod,
    );
    if (value == null || !mounted) return;
    setState(() => UserProfile.defaultDeliveryMethod = value);
    await LocalAuthService.persistPreferences();
  }

  Future<void> _selectRentalDuration() async {
    final current = UserProfile.defaultRentalDays;
    final value = await _chooseSetting(
      title: 'Duração padrão',
      options: const ['1 dia', '3 dias', '7 dias'],
      selected: current == 1 ? '1 dia' : '$current dias',
    );
    if (value == null || !mounted) return;
    setState(() {
      UserProfile.defaultRentalDays = switch (value) {
        '1 dia' => 1,
        '7 dias' => 7,
        _ => 3,
      };
    });
    await LocalAuthService.persistPreferences();
  }

  Future<void> _selectFavoritePlatform() async {
    final value = await _chooseSetting(
      title: 'Plataforma favorita',
      options: const [
        'Todas',
        'PlayStation 5',
        'Xbox Series X',
        'Nintendo Switch',
      ],
      selected: UserProfile.favoritePlatform,
    );
    if (value == null || !mounted) return;
    setState(() => UserProfile.favoritePlatform = value);
    await LocalAuthService.persistPreferences();
  }

  Future<void> _editDeliveryAddress() async {
    final profile = UserProfile.currentUser;
    final addressParts = profile.address.split(' • ');
    var street = addressParts.length == 4 ? addressParts[0] : profile.address;
    var neighborhood = addressParts.length == 4 ? addressParts[1] : '';
    var city = addressParts.length == 4 ? addressParts[2] : profile.city;
    var postalCode = addressParts.length == 4 ? addressParts[3] : '';
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Endereço de entrega',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('delivery-street'),
                  initialValue: street,
                  onChanged: (value) => street = value,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe a rua e o número.'
                      : null,
                  decoration: const InputDecoration(labelText: 'Rua e número'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('delivery-neighborhood'),
                  initialValue: neighborhood,
                  onChanged: (value) => neighborhood = value,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe o bairro.'
                      : null,
                  decoration: const InputDecoration(labelText: 'Bairro'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('delivery-city'),
                  initialValue: city,
                  onChanged: (value) => city = value,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe a cidade e a UF.'
                      : null,
                  decoration: const InputDecoration(labelText: 'Cidade/UF'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('delivery-zip'),
                  initialValue: postalCode,
                  onChanged: (value) => postalCode = value,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe o CEP.'
                      : null,
                  decoration: const InputDecoration(labelText: 'CEP'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(sheetContext, true);
                    }
                  },
                  child: const Text('Salvar endereço'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (shouldSave != true || !mounted) return;
    final address = [
      street.trim(),
      neighborhood.trim(),
      city.trim(),
      postalCode.trim(),
    ].join(' • ');
    final saved = await LocalAuthService.updateCurrentUserProfile(
      name: profile.displayName,
      phone: profile.phone,
      cpf: profile.cpf,
      profileImagePath: profile.profileImagePath,
      city: city,
      address: address,
    );
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o perfil.')),
      );
      return;
    }
    setState(() {});
  }

  Future<void> _showAbout() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (sheetContext) =>
          Padding(padding: const EdgeInsets.all(20), child: _buildAboutCard()),
    );
  }

  Future<void> _editPlayerDetails() async {
    final profile = UserProfile.currentUser;
    var displayName = profile.displayName;
    var phone = profile.phone;
    var cpf = profile.cpf;
    var profileImagePath = profile.profileImagePath;
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Editar dados do jogador',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: _profileAvatar(
                      profile.copyWith(
                        profileImagePath: profileImagePath,
                        clearProfileImage: profileImagePath == null,
                      ),
                      displayName.trim().isEmpty
                          ? 'J'
                          : displayName.trim().substring(0, 1).toUpperCase(),
                      size: 72,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('choose-profile-photo'),
                    onPressed: () async {
                      try {
                        final path = widget.profileImagePicker != null
                            ? await widget.profileImagePicker!()
                            : (await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                imageQuality: 85,
                              ))?.path;
                        if (path != null) {
                          setSheetState(() => profileImagePath = path);
                        }
                      } catch (error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Não foi possível selecionar a foto: $error',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Escolher foto da galeria'),
                  ),
                  if (profileImagePath != null)
                    TextButton(
                      key: const ValueKey('remove-profile-photo'),
                      onPressed: () =>
                          setSheetState(() => profileImagePath = null),
                      child: const Text('Remover foto'),
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const ValueKey('profile-name'),
                    initialValue: displayName,
                    onChanged: (value) => displayName = value,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe seu nome.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('profile-phone'),
                    initialValue: phone,
                    onChanged: (value) => phone = value,
                    decoration: const InputDecoration(
                      labelText: 'Telefone/WhatsApp',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe seu telefone.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('profile-cpf'),
                    initialValue: cpf,
                    onChanged: (value) => cpf = value,
                    decoration: const InputDecoration(labelText: 'CPF'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return LocalAuthService.isValidCpf(value)
                          ? null
                          : 'Informe um CPF válido.';
                    },
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(sheetContext, true);
                      }
                    },
                    child: const Text('Salvar dados'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (shouldSave == true && mounted) {
      final saved = await LocalAuthService.updateCurrentUserProfile(
        name: displayName,
        phone: phone,
        cpf: cpf,
        profileImagePath: profileImagePath,
      );
      if (!mounted) return;
      if (!saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Informe um CPF válido.')));
        return;
      }
      setState(() {});
    }
  }

  Future<void> _confirmClearRentalHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpar histórico de pedidos?'),
        content: const Text(
          'Esta ação remove todas as solicitações demonstrativas desta sessão.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Limpar pedidos'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(Rental.localRequests.clear);
    await LocalStorageService.saveRentals([]);
  }

  Future<void> _showRentalTerms() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Termos de Locação e Caução',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Os equipamentos são testados antes da entrega. Cabos e '
              'acessórios originais são conferidos na retirada e devem '
              'ser devolvidos junto com o produto, sem danos físicos. '
              'Valores e caução são apenas demonstrativos; esta versão '
              'não realiza cobrança nem reserva real.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    _tabHistory.clear();
    await LocalAuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Widget _buildCategoriesTab() {
    const categories = [
      (
        'Consoles',
        Icons.sports_esports_rounded,
        'Consoles para jogar em casa ou em movimento.',
      ),
      (
        'Jogos',
        Icons.videogame_asset_rounded,
        'Jogos físicos para suas plataformas favoritas.',
      ),
      (
        'Pacotes',
        Icons.card_giftcard_rounded,
        'Combinações de consoles, jogos e acessórios.',
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Explore categorias',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: _textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha o que combina com a sua próxima sessão.',
              style: TextStyle(color: _textPrimary.withValues(alpha: 0.68)),
            ),
            const SizedBox(height: 22),
            for (final category in categories) ...[
              _buildCategoryCard(category.$1, category.$2, category.$3),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String name, IconData icon, String description) {
    final itemCount = mockProducts
        .where((product) => product.category == name)
        .length;
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _selectCategory(name),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.alphaBlend(
                  AppTheme.emeraldAccent.withValues(alpha: 0.07),
                  _surface,
                ),
                _surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _textPrimary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary.withValues(alpha: 0.68),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$itemCount ${itemCount == 1 ? 'item' : 'itens'} demonstrativos',
                      style: TextStyle(color: _accent, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: _accent),
            ],
          ),
        ),
      ),
    );
  }
}
