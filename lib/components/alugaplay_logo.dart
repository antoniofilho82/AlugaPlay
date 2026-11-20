import 'package:material_ui/material_ui.dart';

/// Emblema gamer compartilhado pelas telas de abertura e autenticação.
class AlugaPlayLogo extends StatelessWidget {
  const AlugaPlayLogo({super.key, this.size = 136});

  final double size;

  static const _deepSurface = Color(0xFF0A140F);
  static const _mint = Color(0xFF34D399);
  static const _emerald = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _deepSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(size * 0.206),
        border: Border.all(color: _mint.withValues(alpha: 0.82), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.16),
            blurRadius: size * 0.22,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: _emerald.withValues(alpha: 0.12),
            blurRadius: size * 0.088,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) =>
              const LinearGradient(colors: [_mint, _emerald])
                  .createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Icon(
            Icons.sports_esports_rounded,
            color: Colors.white,
            size: size * 0.47,
          ),
        ),
      ),
    );
  }
}
