import 'package:material_ui/material_ui.dart';

import '../../routes/app_routes.dart';
import '../../services/local_auth_service.dart';
import '../../services/startup_service.dart';

const _nightBlue = Color(0xFF050811);
const _splashCanvas = Color(0xFF000000);

/// Mostra a arte da marca enquanto os dados locais são restaurados.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashAsset = 'assets/images/splash_screen.png';
  static const _minimumVisibleDuration = Duration(seconds: 3);

  late final AnimationController _minimumVisibilityController;
  bool _startupReady = false;
  bool _startupFailed = false;
  bool _retryingStartup = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _minimumVisibilityController =
        AnimationController(vsync: this, duration: _minimumVisibleDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _navigateWhenReady();
          });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _minimumVisibilityController.forward();
      _restoreAndNavigate();
    });
  }

  Future<void> _restoreAndNavigate() async {
    if (!StartupService.isReady) {
      await StartupService.initialization;
    }
    if (!mounted) return;
    if (StartupService.error != null) {
      setState(() => _startupFailed = true);
      return;
    }
    _startupReady = true;
    _navigateWhenReady();
  }

  Future<void> _retryStartup() async {
    setState(() {
      _startupFailed = false;
      _retryingStartup = true;
    });
    await StartupService.retry();
    if (!mounted) return;
    setState(() {
      _retryingStartup = false;
      _startupFailed = StartupService.error != null;
    });
    if (!_startupFailed) {
      _startupReady = true;
      _navigateWhenReady();
    }
  }

  void _navigateWhenReady() {
    if (!mounted ||
        _hasNavigated ||
        !_startupReady ||
        !_minimumVisibilityController.isCompleted) {
      return;
    }
    _hasNavigated = true;
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Navigator.of(context).pushReplacementNamed(
      LocalAuthService.shouldAutoLogin ? AppRoutes.home : AppRoutes.login,
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 172,
      height: 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: AnimatedBuilder(
          animation: _minimumVisibilityController,
          builder: (context, _) => LinearProgressIndicator(
            key: const ValueKey('splash-progress'),
            value: _minimumVisibilityController.value,
            minHeight: 5,
            backgroundColor: const Color(0xFF1E293B),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
          ),
        ),
      ),
    );
  }

  Widget _buildStartupError() {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 76,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _nightBlue.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF263654)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Não foi possível restaurar os dados locais.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFF8FAFC)),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const ValueKey('splash-retry'),
                onPressed: _retryingStartup ? null : _retryStartup,
                child: Text(
                  _retryingStartup ? 'Restaurando...' : 'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Libera o controlador de animação e impede navegação após remoção da tela.
  @override
  void dispose() {
    _minimumVisibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _splashCanvas,
      body: Semantics(
        label: 'AlugaPlay',
        image: true,
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  _splashAsset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    FlutterError.reportError(
                      FlutterErrorDetails(
                        exception: error,
                        stack: stackTrace,
                        library: 'image resource service',
                        context: ErrorDescription(
                          'while loading the AlugaPlay splash image',
                        ),
                      ),
                    );
                    return const ColoredBox(color: _splashCanvas);
                  },
                ),
              ),
              if (_startupFailed)
                _buildStartupError()
              else
                Positioned(
                  bottom: 44,
                  left: 0,
                  right: 0,
                  child: Center(child: _buildProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
