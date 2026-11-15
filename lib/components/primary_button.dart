import 'package:material_ui/material_ui.dart';

/// Botão de ação compartilhado para manter dimensões e cores consistentes.
class PrimaryButton extends StatelessWidget {
  /// Permite reutilizar o mesmo botão com rótulo, ícone e tamanho ajustáveis.
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isCompact = false,
  });

  /// Texto exibido no botão.
  final String label;

  /// Ação executada ao tocar; `null` desativa o botão.
  final VoidCallback? onPressed;

  /// Ícone opcional exibido antes do rótulo.
  final IconData? icon;

  /// Reduz altura e espaçamentos para caber em cartões compactos.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // O texto pode encolher com reticências para evitar estouro horizontal.
    return SizedBox(
      height: isCompact ? 38 : 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isCompact ? 16 : 20),
              SizedBox(width: isCompact ? 6 : 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
