import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../components/alugaplay_logo.dart';
import '../../routes/app_routes.dart';
import '../../services/local_auth_service.dart';
import '../../services/startup_service.dart';

const _deepEmerald = Color(0xFF060D09);
const _emerald = Color(0xFF16A34A);
const _brightEmerald = Color(0xFF22C55E);
const _mint = Color(0xFF34D399);

/// Apresenta a identidade do AlugaPlay enquanto prepara a entrada no app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    // O primeiro frame mostra a barra vazia; a navegação aguarda a restauração.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.forward();
      _timer = Timer(const Duration(milliseconds: 1500), () async {
        if (!StartupService.isReady) {
          await StartupService.initialization;
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          LocalAuthService.shouldAutoLogin ? AppRoutes.home : AppRoutes.login,
        );
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepEmerald,
      body: Semantics(
        label: 'AlugaPlay',
        child: CustomPaint(
          painter: const _EmeraldWavesPainter(),
          child: SizedBox.expand(
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: ExcludeSemantics(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AlugaPlayLogo(),
                          const SizedBox(height: 28),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Aluga',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Play',
                                  style: TextStyle(color: _brightEmerald),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Consoles, jogos e pacotes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFABB8B0),
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 44,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        key: const ValueKey('splash-progress-container'),
                        width: 172,
                        height: 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, _) => Stack(
                              fit: StackFit.expand,
                              children: [
                                const ColoredBox(
                                  key: ValueKey('splash-progress-track'),
                                  color: Color(0xFF1A2E23),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [_brightEmerald, _mint],
                                      ).createShader(bounds),
                                  blendMode: BlendMode.srcIn,
                                  child: LinearProgressIndicator(
                                    key: const ValueKey('splash-progress'),
                                    value: _progressAnimation.value,
                                    minHeight: 5,
                                    backgroundColor: Colors.transparent,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmeraldWavesPainter extends CustomPainter {
  const _EmeraldWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final topLeft = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.76, 0)
      ..cubicTo(
        size.width * 0.53,
        size.height * 0.07,
        size.width * 0.32,
        size.height * 0.11,
        0,
        size.height * 0.31,
      )
      ..close();
    final topAccent = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.55, 0)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.06,
        size.width * 0.17,
        size.height * 0.12,
        0,
        size.height * 0.22,
      )
      ..close();
    final bottomRight = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.22, size.height)
      ..cubicTo(
        size.width * 0.49,
        size.height * 0.91,
        size.width * 0.72,
        size.height * 0.84,
        size.width,
        size.height * 0.61,
      )
      ..close();
    final bottomAccent = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.49, size.height)
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.92,
        size.width * 0.86,
        size.height * 0.82,
        size.width,
        size.height * 0.73,
      )
      ..close();
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _brightEmerald.withValues(alpha: 0.14),
        _emerald.withValues(alpha: 0.12),
        const Color(0xFF059669).withValues(alpha: 0.08),
      ],
    );
    final paint = Paint()
      ..isAntiAlias = true
      ..shader = gradient.createShader(bounds);

    canvas
      ..drawPath(topLeft, paint)
      ..drawPath(topAccent, paint)
      ..drawPath(bottomRight, paint)
      ..drawPath(bottomAccent, paint);
  }

  @override
  bool shouldRepaint(covariant _EmeraldWavesPainter oldDelegate) => false;
}
