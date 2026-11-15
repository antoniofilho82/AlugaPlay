import 'product.dart';

/// Registra em memória os dados de uma solicitação demonstrativa de aluguel.
class Rental {
  /// Armazena o produto e o período usado para calcular o valor estimado.
  const Rental({
    required this.id,
    required this.product,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.estimatedTotal,
    required this.notes,
    this.status = 'Solicitação demonstrativa enviada',
  });

  /// Identificador local da solicitação.
  final String id;

  /// Produto escolhido na vitrine.
  final Product product;

  /// Data normalizada de retirada.
  final DateTime startDate;

  /// Data prevista para devolução.
  final DateTime endDate;

  /// Duração calculada entre as duas datas.
  final int totalDays;

  /// Total estimado, sem efetuar cobrança real.
  final double estimatedTotal;

  /// Observações informadas no formulário.
  final String notes;

  /// Situação inicial apresentada ao usuário.
  final String status;

  /// Coleção em memória; os registros existem apenas durante a execução do app.
  static final List<Rental> localRequests = [];
}
