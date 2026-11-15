import 'package:material_ui/material_ui.dart';

import '../../components/primary_button.dart';
import '../../data/mock_products.dart';
import '../../models/product.dart';
import '../../routes/app_routes.dart';

/// Apresenta as informações do produto selecionado no catálogo.
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // A rota entrega o produto selecionado; o primeiro item serve de fallback
    // para abertura direta, e o estado vazio permanece tratado abaixo.
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final product = arguments is Product
        ? arguments
        : mockProducts.isNotEmpty
        ? mockProducts.first
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        title: Text(
          'Detalhes do Produto',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: product == null
          ? _buildMissingProduct(context)
          : _buildProductDetails(context, product),
      bottomNavigationBar: product == null
          ? null
          : _buildRentalBar(context, product),
    );
  }

  Widget _buildProductDetails(BuildContext context, Product product) {
    final colorScheme = Theme.of(context).colorScheme;
    // As seções ficam numa única rolagem para acomodar descrições e listas longas.
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProductHero(context, product),
            const SizedBox(height: 20),
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildAvailability(context, product.demoAvailabilityLabel),
            // Informações descritivas e técnicas são opcionais conforme o produto.
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Sobre o produto'),
            const SizedBox(height: 8),
            Text(
              product.fullDescription,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.55,
              ),
            ),
            if (product.specs.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Características técnicas'),
              const SizedBox(height: 10),
              _buildListCard(context, product.specs, icon: Icons.check_rounded),
            ],
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Itens incluídos'),
            const SizedBox(height: 10),
            product.includedItems.isEmpty
                ? _buildEmptyIncludedItems(context)
                : _buildListCard(
                    context,
                    product.includedItems,
                    icon: Icons.check_circle_outline_rounded,
                  ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHero(BuildContext context, Product product) {
    final colorScheme = Theme.of(context).colorScheme;
    // A arte usa asset quando disponível e recorre ao ícone sem interromper a tela.
    return Container(
      height: 228,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          Center(
            child: product.imageAsset == null
                ? Icon(product.icon, size: 88, color: colorScheme.secondary)
                : Image.asset(
                    product.imageAsset!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      product.icon,
                      size: 88,
                      color: colorScheme.secondary,
                    ),
                  ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadge(context, product.category),
                _buildBadge(context, product.platform),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAvailability(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, color: colorScheme.secondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label. Esta informação é demonstrativa e não representa estoque real.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildListCard(
    BuildContext context,
    List<String> items, {
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    // Cada item pode quebrar linha; divisórias ajudam a separar listas maiores.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0)
              Divider(height: 1, color: colorScheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: colorScheme.secondary, size: 20),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      items[index],
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyIncludedItems(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Os itens incluídos serão informados nesta seção.',
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildRentalBar(BuildContext context, Product product) {
    final colorScheme = Theme.of(context).colorScheme;
    // O rodapé mantém preço e próxima ação acessíveis enquanto os detalhes rolam.
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valor do aluguel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.formattedPrice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    product.billingUnit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: PrimaryButton(
                label: 'Solicitar Aluguel',
                icon: Icons.calendar_month_rounded,
                // Repassa a mesma instância recebida da Home para a solicitação.
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamed(AppRoutes.rental, arguments: product),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingProduct(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Evita uma tela vazia quando a rota é aberta sem um produto válido.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: colorScheme.secondary,
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              'Produto não encontrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Volte ao catálogo e escolha um produto para ver os detalhes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Voltar',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
