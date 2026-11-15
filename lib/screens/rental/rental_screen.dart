import 'package:material_ui/material_ui.dart';

import '../../components/primary_button.dart';
import '../../data/mock_products.dart';
import '../../models/product.dart';
import '../../models/rental.dart';
import '../../routes/app_routes.dart';

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

  // As datas iniciais já oferecem um exemplo válido de três dias.
  late DateTime _startDate;
  late DateTime _endDate;
  // Observações ficam no controlador apenas enquanto o formulário está aberto.
  final TextEditingController _notesController = TextEditingController();
  String? _dateErrorMessage;

  @override
  void initState() {
    super.initState();
    // Datas sem horário evitam diferenças de duração causadas por horas/minutos.
    final today = _normalizeDate(DateTime.now());
    _startDate = today.add(const Duration(days: 1));
    _endDate = _startDate.add(const Duration(days: 3));
  }

  @override
  void dispose() {
    // Encerra o controlador quando a solicitação é fechada.
    _notesController.dispose();
    super.dispose();
  }

  // Constrói uma data à meia-noite para comparar apenas dia, mês e ano.
  static DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  // Mantém o formato brasileiro curto usado em cartões e confirmações.
  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  // A estimativa usa vírgula decimal e não representa uma cobrança real.
  static String _formatCurrency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  // Recupera o argumento de rota e mantém um fallback para aberturas diretas.
  Product? _productFromRoute(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Product) return arguments;
    return mockProducts.isEmpty ? null : mockProducts.first;
  }

  // A diferença entre datas já normalizadas representa dias corridos inteiros.
  int get _totalDays {
    final normalizedStart = _normalizeDate(_startDate);
    final normalizedEnd = _normalizeDate(_endDate);
    final diffDays = normalizedEnd.difference(normalizedStart).inDays;
    return diffDays < 1 ? 0 : diffDays;
  }

  // Tarifas semanais são convertidas para uma base diária proporcional.
  double _estimatedTotal(Product product) {
    if (_totalDays < 1) return 0;
    final dailyRate = product.billingUnit.toLowerCase().contains('semana')
        ? product.rentalPrice / 7.0
        : product.rentalPrice;
    return _totalDays * dailyRate;
  }

  // A validação bloqueia datas iguais ou anteriores à retirada.
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

  Future<void> _selectDate({required bool isStartDate}) async {
    // Limita o calendário ao intervalo de um ano e aplica a paleta no seletor.
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
    // Normaliza também o valor retornado pelo seletor antes de atualizar a tela.
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
    // Impede o registro mesmo se a validação visual ainda não tiver sido acionada.
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
    );
    // O protótipo mantém as solicitações somente na memória desta execução.
    Rental.localRequests.add(rental);

    // A confirmação deixa claro o caráter local e retorna à Home sem empilhar telas.
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
              _dialogDetail(
                'Valor estimado',
                _formatCurrency(rental.estimatedTotal),
              ),
              const SizedBox(height: 10),
              Text(
                'Os dados ficam armazenados apenas localmente enquanto o app '
                'estiver em execução. Esta etapa não realiza pagamento real.',
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
    // Reutiliza o mesmo alinhamento para os dados resumidos da confirmação.
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
    // O mesmo argumento selecionado acompanha o usuário até o formulário.
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
    // A rolagem permite preencher observações e rever os valores com o teclado aberto.
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
          LayoutBuilder(
            builder: (context, constraints) {
              // Em larguras muito estreitas, empilha as datas para evitar overflow.
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
                  'Informe horário preferido, endereço demonstrativo de '
                  'entrega ou detalhes sobre acessórios.',
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

  Widget _buildProductSummary(Product product) {
    // Identifica o item e sua tarifa antes de solicitar o período.
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
    // Toda a área do cartão abre o seletor de data correspondente.
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
              Icon(
                Icons.calendar_month_rounded,
                color: _accent,
                size: 22,
              ),
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
    // Recalcula o resumo com as datas atuais para refletir cada alteração.
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
    // Flex permite que valores extensos ocupem mais de uma linha sem estourar.
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
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissingProduct(BuildContext context) {
    // Oferece retorno ao catálogo se a tela não receber um produto válido.
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
