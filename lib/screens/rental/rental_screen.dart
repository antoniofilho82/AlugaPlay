import 'package:material_ui/material_ui.dart';

import '../../components/primary_button.dart';
import '../../data/mock_products.dart';
import '../../models/product.dart';
import '../../models/rental.dart';
import '../../models/user_profile.dart';
import '../../routes/app_routes.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_theme.dart';

/// Permite escolher datas e registrar uma estimativa local de aluguel.
class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> {
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surface;
  Color get _surfaceContainer =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _accent => Theme.of(context).colorScheme.secondary;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;

  late DateTime _startDate;
  late DateTime _endDate;
  late String _deliveryMethod;
  final TextEditingController _notesController = TextEditingController();
  late final TextEditingController _deliveryAddressController;
  String? _dateErrorMessage;

  @override
  void initState() {
    super.initState();
    final today = _normalizeDate(DateTime.now());
    _startDate = today.add(const Duration(days: 1));
    _endDate = _startDate.add(Duration(days: UserProfile.defaultRentalDays));
    _deliveryMethod = UserProfile.defaultDeliveryMethod;
    final profile = UserProfile.currentUser;
    _deliveryAddressController = TextEditingController(
      text: profile.address.trim().isNotEmpty ? profile.address : profile.city,
    );
  }

  @override
  void dispose() {
    // Libera os campos de texto quando a tela de locação sai da árvore.
    _notesController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  static DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String _formatCurrency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  // A rota normal recebe o produto; a abertura direta usa o primeiro item local.
  Product? _productFromRoute(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Product) return arguments;
    return mockProducts.isEmpty ? null : mockProducts.first;
  }

  int get _totalDays {
    final normalizedStart = _normalizeDate(_startDate);
    final normalizedEnd = _normalizeDate(_endDate);
    final diffDays = normalizedEnd.difference(normalizedStart).inDays;
    return diffDays < 1 ? 0 : diffDays;
  }

  // Produtos semanais são rateados por dia; o catálogo atual só usa diárias.
  double _estimatedTotal(Product product) {
    if (_totalDays < 1) return 0;
    final dailyRate = product.billingUnit.toLowerCase().contains('semana')
        ? product.rentalPrice / 7.0
        : product.rentalPrice;
    return _totalDays * dailyRate;
  }

  void _validateDates() {
    final normalizedStart = _normalizeDate(_startDate);
    final normalizedEnd = _normalizeDate(_endDate);
    final diffDays = normalizedEnd.difference(normalizedStart).inDays;
    setState(() {
      _dateErrorMessage = diffDays < 1
          ? 'A data de término deve ser posterior à data de início '
                '(mínimo de 1 dia).'
          : null;
    });
  }

  void _setRentalDuration(int days) {
    setState(() {
      _endDate = _startDate.add(Duration(days: days));
      _dateErrorMessage = null;
    });
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final today = _normalizeDate(DateTime.now());
    final lastDate = today.add(const Duration(days: 365));
    final selectedDate = isStartDate ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: today,
      lastDate: lastDate,
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: colorScheme.surface,
              surfaceTintColor: colorScheme.surface,
              headerBackgroundColor: colorScheme.primaryContainer,
              headerForegroundColor: colorScheme.onPrimaryContainer,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;
    setState(() {
      if (isStartDate) {
        _startDate = _normalizeDate(pickedDate);
      } else {
        _endDate = _normalizeDate(pickedDate);
      }
    });
    _validateDates();
  }

  Future<void> _confirmRequest(Product product) async {
    // Revalida antes de persistir, mesmo que a mensagem visual ainda não tenha sido exibida.
    if (_totalDays < 1) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Selecione um período válido para continuar.'),
            backgroundColor: _surfaceContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final rental = Rental(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      product: product,
      startDate: _normalizeDate(_startDate),
      endDate: _normalizeDate(_endDate),
      totalDays: _totalDays,
      estimatedTotal: _estimatedTotal(product),
      notes: _notesController.text.trim(),
      deliveryMethod: _deliveryMethod,
      deliveryAddress: _deliveryMethod == 'Entrega Delivery'
          ? _deliveryAddressController.text.trim()
          : '',
    );
    Rental.localRequests.add(rental);
    // Persiste o snapshot para que a aba Meus Aluguéis o restaure após reinício.
    await LocalStorageService.saveRentals(
      Rental.localRequests.map((request) => request.toJson()).toList(),
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        surfaceTintColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _accent.withValues(alpha: 0.2)),
        ),
        icon: Icon(Icons.check_circle_rounded, color: _accent, size: 42),
        title: Text(
          'Solicitação registrada',
          textAlign: TextAlign.center,
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _dialogDetail(
                'Período',
                '${_formatDate(rental.startDate)} a '
                    '${_formatDate(rental.endDate)}',
              ),
              _dialogDetail('Duração', '${rental.totalDays} dia(s)'),
              _dialogDetail('Modalidade', _deliveryMethod),
              if (_deliveryMethod == 'Entrega Delivery')
                _dialogDetail('Endereço', _deliveryAddressController.text),
              _dialogDetail(
                'Valor estimado',
                _formatCurrency(rental.estimatedTotal),
              ),
              const SizedBox(height: 10),
              Text(
                'Os dados ficam armazenados localmente neste aparelho. Esta '
                'etapa não realiza pagamento real.',
                style: TextStyle(
                  color: _textPrimary.withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Voltar ao Catálogo',
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).popUntil(
                  (route) =>
                      route.settings.name == AppRoutes.home || route.isFirst,
                );
              },
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  Widget _dialogDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: _textPrimary.withValues(alpha: 0.68)),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _productFromRoute(context);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _textPrimary,
        title: const Text('Solicitar Aluguel'),
      ),
      body: product == null
          ? _buildMissingProduct(context)
          : _buildForm(product),
      bottomNavigationBar: product == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: PrimaryButton(
                  label: 'Confirmar Solicitação',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () => _confirmRequest(product),
                ),
              ),
            ),
    );
  }

  Widget _buildForm(Product product) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProductSummary(product),
          const SizedBox(height: 24),
          Text(
            'Período do aluguel',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _durationChip(1, '1 dia'),
              _durationChip(3, '3 dias (Fim de semana)'),
              _durationChip(7, '7 dias (Semana)'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Modalidade de entrega',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _deliveryChip('Retirada na Loja'),
              _deliveryChip('Entrega Delivery'),
            ],
          ),
          if (_deliveryMethod == 'Entrega Delivery') ...[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('rental-delivery-address'),
              controller: _deliveryAddressController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: _textPrimary),
              decoration: const InputDecoration(
                labelText: 'Endereço para entrega',
                hintText: 'Rua, bairro, cidade/UF e CEP',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ],
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final startCard = _buildDateCard(
                label: 'Data de início',
                date: _startDate,
                onTap: () => _selectDate(isStartDate: true),
              );
              final endCard = _buildDateCard(
                label: 'Data de término',
                date: _endDate,
                onTap: () => _selectDate(isStartDate: false),
              );
              if (constraints.maxWidth < 360) {
                return Column(
                  children: [startCard, const SizedBox(height: 10), endCard],
                );
              }
              return Row(
                children: [
                  Expanded(child: startCard),
                  const SizedBox(width: 10),
                  Expanded(child: endCard),
                ],
              );
            },
          ),
          if (_dateErrorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _dateErrorMessage!,
              style: TextStyle(
                color: _accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildConservationPolicyCard(),
          const SizedBox(height: 24),
          Text(
            'Observações (opcional)',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 3,
            minLines: 3,
            style: TextStyle(color: _textPrimary),
            decoration: InputDecoration(
              hintText:
                  'Informe horário preferido ou detalhes sobre acessórios.',
              hintStyle: TextStyle(
                color: _textPrimary.withValues(alpha: 0.55),
                height: 1.4,
              ),
              filled: true,
              fillColor: _surface,
              alignLabelWithHint: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _textPrimary.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _accent),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildEstimateCard(product),
        ],
      ),
    );
  }

  Widget _durationChip(int days, String label) {
    final selected = _totalDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _setRentalDuration(days),
      selectedColor: AppTheme.blueAccent.withValues(alpha: 0.22),
      side: BorderSide(
        color: selected
            ? AppTheme.blue
            : Theme.of(context).colorScheme.outlineVariant,
      ),
      labelStyle: TextStyle(
        color: selected ? AppTheme.blueDeep : _textPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _deliveryChip(String method) {
    final selected = _deliveryMethod == method;
    return ChoiceChip(
      label: Text(method),
      selected: selected,
      onSelected: (_) => setState(() {
        _deliveryMethod = method;
        if (method == 'Entrega Delivery' &&
            _deliveryAddressController.text.isEmpty) {
          final profile = UserProfile.currentUser;
          _deliveryAddressController.text = profile.address.trim().isNotEmpty
              ? profile.address
              : profile.city;
        }
      }),
      selectedColor: AppTheme.blueAccent.withValues(alpha: 0.22),
      side: BorderSide(
        color: selected
            ? AppTheme.blue
            : Theme.of(context).colorScheme.outlineVariant,
      ),
      labelStyle: TextStyle(
        color: selected ? AppTheme.blueDeep : _textPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildConservationPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.heroBannerGradient(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.blueAccent.withValues(alpha: 0.38)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: AppTheme.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Política de Conservação e Caução',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'O equipamento é testado antes da locação. Na retirada, '
                  'conferimos os cabos originais; na devolução, pedimos que '
                  'o produto retorne sem danos físicos. A caução e as '
                  'condições são demonstrativas nesta versão.',
                  style: TextStyle(
                    color: _textPrimary.withValues(alpha: 0.76),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSummary(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textPrimary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: product.imageAsset == null
                ? Icon(product.icon, color: _accent, size: 34)
                : Image.asset(
                    product.imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(product.icon, color: _accent, size: 34),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${product.category} • ${product.platform}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _accent, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  '${product.formattedPrice} ${product.billingUnit}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary.withValues(alpha: 0.78),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _textPrimary.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: _accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary.withValues(alpha: 0.66),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateCard(Product product) {
    final totalDays = _totalDays;
    final estimatedTotal = _estimatedTotal(product);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resumo do valor estimado',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _summaryRow(
            'Tarifa base',
            '${product.formattedPrice} ${product.billingUnit}',
          ),
          const SizedBox(height: 10),
          _summaryRow('Modalidade', _deliveryMethod),
          const SizedBox(height: 10),
          if (_deliveryMethod == 'Entrega Delivery') ...[
            _summaryRow('Endereço', _deliveryAddressController.text),
            const SizedBox(height: 10),
          ],
          _summaryRow('Período', '$totalDays dia(s)'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              color: _textPrimary.withValues(alpha: 0.12),
              height: 1,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total estimado',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatCurrency(estimatedTotal),
                style: TextStyle(
                  color: _accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Estimativa demonstrativa. Nenhum pagamento real é realizado nesta etapa.',
            style: TextStyle(
              color: _textPrimary.withValues(alpha: 0.62),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: _textPrimary.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildMissingProduct(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, color: _accent, size: 44),
            const SizedBox(height: 12),
            Text(
              'Nenhum produto disponível',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Volte ao catálogo para selecionar um produto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textPrimary.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Voltar ao Catálogo',
              onPressed: () => Navigator.of(context).popUntil(
                (route) =>
                    route.settings.name == AppRoutes.home || route.isFirst,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
