import 'package:material_ui/material_ui.dart';

/// Representa um item do catálogo, seja console, jogo físico ou pacote.
class Product {
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

  final String id;

  final String name;

  final String category;

  final String platform;

  final String shortDescription;

  final String fullDescription;

  final double rentalPrice;

  final String billingUnit;

  final IconData icon;

  final String? imageAsset;

  final List<String> specs;

  final List<String> includedItems;

  final String demoAvailabilityLabel;

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
