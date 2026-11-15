import 'package:material_ui/material_ui.dart';

import '../../components/category_item.dart';
import '../../components/product_card.dart';
import '../../components/primary_button.dart';
import '../../data/mock_products.dart';
import '../../models/product.dart';
import '../../models/rental.dart';
import '../../models/user_profile.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

/// Reúne o catálogo e as áreas de navegação do cliente.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surface;
  Color get _accent => Theme.of(context).colorScheme.secondary;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;

  // Os filtros compartilham os mesmos rótulos usados nos cartões de categoria.
  static const List<String> _categories = [
    'Todos',
    'Consoles',
    'Jogos',
    'Pacotes',
  ];

  // Cada categoria tem um ícone correspondente na navegação visual.
  static const Map<String, IconData> _categoryIcons = {
    'Todos': Icons.grid_view_rounded,
    'Consoles': Icons.sports_esports_rounded,
    'Jogos': Icons.videogame_asset_rounded,
    'Pacotes': Icons.card_giftcard_rounded,
  };

  // A busca e a aba selecionada pertencem ao estado desta tela.
  final TextEditingController _searchController = TextEditingController();
  final List<int> _tabHistory = [];
  int _selectedTab = 0;
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  @override
  void dispose() {
    // Libera o campo de busca ao sair da Home.
    _searchController.dispose();
    super.dispose();
  }

  // Combina categoria e termo para que um filtro não anule o outro.
  List<Product> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    return mockProducts.where((product) {
      final matchesCategory =
          _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.platform.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
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

  void _navigateToTab(int index) {
    if (index == _selectedTab) return;

    setState(() {
      if (_tabHistory.isEmpty || _tabHistory.last != _selectedTab) {
        _tabHistory.add(_selectedTab);
      }
      _selectedTab = index;
    });
  }

  // Limpa tanto o texto visível quanto os valores usados no filtro.
  void _clearFilters() {
    setState(() {
      _selectedCategory = 'Todos';
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // Informa que a notificação é apenas uma demonstração nesta versão.
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

  void _toggleTheme() {
    AppTheme.toggleTheme(Theme.of(context).brightness);
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack preserva o estado das abas enquanto o usuário alterna entre elas.
    return PopScope(
      canPop:
          _tabHistory.isEmpty &&
          _selectedTab == 0 &&
          _searchQuery.isEmpty &&
          _selectedCategory == 'Todos',
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_tabHistory.isNotEmpty) {
          final previousTab = _tabHistory.removeLast();
          setState(() => _selectedTab = previousTab);
        } else if (_selectedTab != 0) {
          setState(() => _selectedTab = 0);
        } else if (_searchQuery.isNotEmpty || _selectedCategory != 'Todos') {
          setState(() {
            _selectedCategory = 'Todos';
            _searchQuery = '';
            _searchController.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: _background,
        // --- Seção: Conteúdo das Abas ---
        body: IndexedStack(
          index: _selectedTab,
          children: [
            _buildHomeTab(),
            _buildCategoriesTab(),
            _buildRentalsTab(),
            _buildProfileTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
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
          backgroundColor: _surface,
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
    );
  }

  Widget _buildHomeTab() {
    // O destaque e a faixa de pacotes não competem com os resultados da busca.
    final products = _filteredProducts;
    final featured = _featuredProduct;
    final showFeatured =
        _searchQuery.trim().isEmpty &&
        _selectedCategory == 'Todos' &&
        featured != null;
    final showPackages =
        _searchQuery.trim().isEmpty &&
        (_selectedCategory == 'Todos' || _selectedCategory == 'Pacotes');
    final packages = mockProducts
        .where((product) => product.category == 'Pacotes')
        .toList();

    return SafeArea(
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // --- Seção: Busca e Categorias ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: _buildHeader(),
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
            // --- Seção: Destaque e Pacotes ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                child: _buildFeaturedCard(featured),
              ),
            ),
          if (showPackages)
            SliverToBoxAdapter(
              // --- Seção: Catálogo Filtrado ---
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
    // A área expansível protege o título quando a largura disponível é pequena.
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
    // Atualiza os resultados conforme o texto muda e oferece limpeza imediata.
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
    // A rolagem horizontal mantém todas as categorias acessíveis em telas estreitas.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Categorias',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: _textPrimary, fontWeight: FontWeight.w700),
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
    // O destaque usa a mesma ação do catálogo para repassar o produto selecionado.
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.24)),
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
    // A lista aparece do registro mais recente para o mais antigo.
    final requests = Rental.localRequests.reversed.toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // --- Seção: Cabeçalho e Contagem ---
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
    // O estado vazio orienta o retorno à vitrine sem criar uma nova rota.
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
    // O cartão reúne período, duração, estimativa e observações da solicitação.
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

  void _cancelRental(Rental rental) {
    // Remove somente o registro escolhido e confirma a ação ao usuário.
    setState(() {
      Rental.localRequests.remove(rental);
    });
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

  Widget _buildProfileTab() {
    // Os dados refletem o perfil e as solicitações mantidos em memória na sessão.
    final profile = UserProfile.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Meu Perfil',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: _textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _textPrimary.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  // --- Seção: Identidade do Jogador ---
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: _background,
                      shape: BoxShape.circle,
                      border: Border.all(color: _accent.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      Icons.sports_esports_rounded,
                      color: _accent,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.gamerTag,
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _profileDetail(Icons.email_outlined, profile.email),
                  const SizedBox(height: 9),
                  _profileDetail(Icons.location_on_outlined, profile.city),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile.accountBadge,
                      textAlign: TextAlign.center,
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
            const SizedBox(height: 16),
            // --- Seção: Resumo e Atalhos ---
            Row(
              children: [
                Expanded(
                  child: _buildProfileSummary(
                    value: '${Rental.localRequests.length}',
                    label: 'Solicitações ativas',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProfileSummary(
                    value: 'Demo',
                    label: 'Modo Protótipo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Atalhos',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: _textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _buildProfileShortcut(
              icon: Icons.receipt_long_outlined,
              label: 'Minhas solicitações de aluguel',
              onTap: () => _navigateToTab(2),
            ),
            const SizedBox(height: 10),
            _buildProfileShortcut(
              icon: Icons.explore_outlined,
              label: 'Explorar catálogo gamer',
              onTap: () => _navigateToTab(0),
            ),
            const SizedBox(height: 22),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              secondary: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              title: const Text('Modo escuro'),
              value: Theme.of(context).brightness == Brightness.dark,
              activeTrackColor: Theme.of(context).colorScheme.primary,
              onChanged: (_) => _toggleTheme(),
            ),
            const SizedBox(height: 12),
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

  Widget _profileDetail(IconData icon, String value) {
    // Expanded e reticências protegem e-mail e localização de textos extensos.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _accent, size: 18),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimary.withValues(alpha: 0.78),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSummary({required String value, required String label}) {
    // Os dois resumos dividem a largura disponível sem impor tamanho fixo.
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _textPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _accent,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _textPrimary.withValues(alpha: 0.72),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileShortcut({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // Atalhos trocam a aba atual, mantendo a navegação no mesmo fluxo.
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _textPrimary.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Icon(icon, color: _accent, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _accent),
            ],
          ),
        ),
      ),
    );
  }

  void _signOut() {
    // Encerra o estado demonstrativo antes de substituir a Home pelo login.
    _tabHistory.clear();
    UserProfile.reset();
    Rental.localRequests.clear();
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Widget _buildCategoriesTab() {
    // Atalhos por categoria reaproveitam os filtros usados na vitrine.
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
    // O cartão aplica a categoria e retorna à lista de produtos.
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
