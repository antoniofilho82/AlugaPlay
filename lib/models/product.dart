import 'package:material_ui/material_ui.dart';

/// Representa um item do catálogo, seja console, jogo físico ou pacote.
class Product {
  /// Mantém os dados do catálogo imutáveis depois de carregados.
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.platform,
    required this.shortDescription,
    required this.fullDescription,
    required this.rentalPrice,
    required this.billingUnit,
    required this.icon,
    this.imageAsset,
    required this.specs,
    required this.includedItems,
    required this.demoAvailabilityLabel,
    this.isFeatured = false,
  }) : assert(
         category == 'Consoles' || category == 'Jogos' || category == 'Pacotes',
         'Category must be Consoles, Jogos, or Pacotes.',
       );

  /// Identificador estável usado para reconhecer o item.
  final String id;

  /// Nome comercial exibido no catálogo.
  final String name;

  /// Categoria aceita pelo catálogo: consoles, jogos ou pacotes.
  final String category;

  /// Plataforma compatível com o item.
  final String platform;

  /// Resumo curto para os cartões da vitrine.
  final String shortDescription;

  /// Descrição detalhada para a tela do produto.
  final String fullDescription;

  /// Preço numérico na unidade indicada em [billingUnit].
  final double rentalPrice;

  /// Unidade de cobrança, como diária ou semanal.
  final String billingUnit;

  /// Ícone local que mantém uma representação disponível sem rede.
  final IconData icon;

  /// Caminho opcional de uma imagem local para uso futuro.
  final String? imageAsset;

  /// Características principais apresentadas nos detalhes.
  final List<String> specs;

  /// Itens que acompanham a locação demonstrativa.
  final List<String> includedItems;

  /// Aviso que deixa claro o caráter demonstrativo da disponibilidade.
  final String demoAvailabilityLabel;

  /// Indica se o item deve aparecer no destaque da vitrine.
  final bool isFeatured;

  /// Formata o preço em Real, com separador de milhar e duas casas decimais.
  String get formattedPrice {
    final parts = rentalPrice.toStringAsFixed(2).split('.');
    final integerPart = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $integerPart,${parts.last}';
  }
}
