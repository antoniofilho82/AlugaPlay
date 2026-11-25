import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Emblema original do AlugaPlay, exibido sem deformar o asset quadrado.
class AlugaPlayLogo extends StatelessWidget {
  const AlugaPlayLogo({super.key, this.size = 136});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1224), Color(0xFF101B36)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.206),
        border: Border.all(color: const Color(0xFF38BDF8), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
            blurRadius: size * 0.22,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFFFACC15).withValues(alpha: 0.12),
            blurRadius: size * 0.088,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.18),
        child: Image.asset(
          'assets/icon/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Wordmark com contorno escuro e brilho azul, sem caixa de fundo.
class AlugaPlayWordmark extends StatelessWidget {
  const AlugaPlayWordmark({
    super.key,
    required this.fontSize,
    this.letterSpacing = 0.2,
    this.alignment = Alignment.center,
  });

  final double fontSize;
  final double letterSpacing;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: letterSpacing,
    );
    final outlineStyle = baseStyle.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = fontSize * (isLight ? 0.055 : 0.08)
        ..color = isLight ? const Color(0xFF1E3A8A) : const Color(0xFF050811),
      shadows: [
        Shadow(
          color: AppTheme.blue.withValues(alpha: isLight ? 0.58 : 0.9),
          blurRadius: fontSize * (isLight ? 0.38 : 0.48),
        ),
        Shadow(
          color: AppTheme.blueAccent.withValues(alpha: isLight ? 0.32 : 0.5),
          blurRadius: fontSize * (isLight ? 0.62 : 0.82),
        ),
      ],
    );
    final fillStyle = baseStyle.copyWith(
      shadows: [
        Shadow(
          color: AppTheme.blue.withValues(alpha: isLight ? 0.42 : 0.78),
          blurRadius: fontSize * (isLight ? 0.4 : 0.52),
        ),
      ],
    );

    return FittedBox(
      alignment: alignment,
      fit: BoxFit.scaleDown,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ExcludeSemantics(
            child: RichText(
              key: const ValueKey('alugaplay-wordmark-outline'),
              text: TextSpan(
                style: outlineStyle,
                children: const [
                  TextSpan(text: 'Aluga'),
                  TextSpan(text: 'Play'),
                ],
              ),
            ),
          ),
          RichText(
            key: const ValueKey('alugaplay-wordmark-fill'),
            text: TextSpan(
              style: fillStyle,
              children: const [
                TextSpan(
                  text: 'Aluga',
                  style: TextStyle(color: AppTheme.gold),
                ),
                TextSpan(
                  text: 'Play',
                  style: TextStyle(color: Color(0xFFF8FAFC)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
