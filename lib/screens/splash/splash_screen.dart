import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

/// Apresenta a identidade do AlugaPlay enquanto prepara a entrada no app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // As animações compartilham um controlador para iniciar e encerrar juntas.
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  // O temporizador encerra a splash sem depender de interação do usuário.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // A curva deixa a entrada do logotipo mais suave do que uma progressão linear.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = curvedAnimation;
    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(curvedAnimation);
    // FadeTransition e ScaleTransition usam a mesma animação de entrada.
    _controller.forward();
    // Após 2,5 segundos, substitui a splash pelo login sem acumular uma rota.
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    });
  }

  @override
  void dispose() {
    // Libera os recursos mesmo se a tela for removida antes do redirecionamento.
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // O conteúdo fica centralizado e seguro em diferentes tamanhos de tela.
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // O emblema mantém as mesmas cores do ícone adaptativo Android.
                            Container(
                              width: 136,
                              height: 136,
                              decoration: BoxDecoration(
                                color: const Color(0xFF13171D),
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(
                                  color: const Color(0xFF22C55E)
                                      .withValues(alpha: 0.24),
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A3326),
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  Icon(
                                    Icons.sports_esports_rounded,
                                    color: const Color(0xFF22C55E),
                                    size: 52,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Aluga',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Play',
                                    style: const TextStyle(
                                      color: AppTheme.emerald,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Consoles, jogos e pacotes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 144,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.72,
                      minHeight: 4,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
