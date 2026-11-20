import '../data/mock_products.dart';
import '../services/local_storage_service.dart';
import 'product.dart';

/// Snapshot local de uma solicitação demonstrativa de aluguel.
class Rental {
  const Rental({
    required this.id,
    required this.product,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.estimatedTotal,
    required this.notes,
    this.status = 'Solicitação demonstrativa enviada',
    this.pin,
    this.serialNumber,
    this.checklist = const [],
    this.deposit = 0,
    this.paymentMethod,
    this.termsAccepted = false,
    this.deliveryMethod = '',
    this.deliveryAddress = '',
  });

  final String id;

  final Product product;

  final DateTime startDate;

  final DateTime endDate;

  final int totalDays;

  final double estimatedTotal;

  final String notes;

  final String status;

  final String? pin;
  final String? serialNumber;
  final List<String> checklist;
  final double deposit;
  final String? paymentMethod;
  final bool termsAccepted;
  final String deliveryMethod;
  final String deliveryAddress;

  /// Serializa PIN, número de série, checklist, caução, pagamento e aceite.
  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': product.id,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalDays': totalDays,
    'estimatedTotal': estimatedTotal,
    'notes': notes,
    'status': status,
    'pin': pin,
    'serialNumber': serialNumber,
    'checklist': checklist,
    'deposit': deposit,
    'paymentMethod': paymentMethod,
    'termsAccepted': termsAccepted,
    'deliveryMethod': deliveryMethod,
    'deliveryAddress': deliveryAddress,
  };

  factory Rental.fromJson(Map<String, dynamic> json) {
    final productId = json['productId'];
    final products = mockProducts.where((product) => product.id == productId);
    if (products.isEmpty) {
      throw FormatException('Produto local não encontrado: $productId');
    }
    final rawChecklist = json['checklist'];
    return Rental(
      id: json['id'] as String,
      product: products.first,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalDays: json['totalDays'] as int,
      estimatedTotal: (json['estimatedTotal'] as num).toDouble(),
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'Solicitação demonstrativa enviada',
      pin: json['pin'] as String?,
      serialNumber: json['serialNumber'] as String?,
      checklist: rawChecklist == null
          ? const []
          : (rawChecklist as List).cast<String>(),
      deposit: (json['deposit'] as num? ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] as String?,
      termsAccepted: json['termsAccepted'] as bool? ?? false,
      deliveryMethod: json['deliveryMethod'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
    );
  }

  static final List<Rental> localRequests = [];

  static Future<void> restoreFromStorage() async {
    localRequests
      ..clear()
      ..addAll(LocalStorageService.loadRentals().map(Rental.fromJson));
  }
}
