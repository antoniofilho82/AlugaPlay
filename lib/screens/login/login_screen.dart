import 'package:material_ui/material_ui.dart';

import '../../components/alugaplay_logo.dart';
import '../../routes/app_routes.dart';
import '../../services/local_auth_service.dart';
import '../../theme/app_theme.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Tela de entrada com validação local de credenciais.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _rememberAccess = LocalAuthService.rememberAccess;
  bool _obscurePassword = true;
  bool _registerPressed = false;
  String? _errorMessage;

  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _surface => Theme.of(context).colorScheme.surface;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: LocalAuthService.rememberedEmail ?? '',
    );
    // A senha nunca é recuperada nem pré-preenchida pela sessão lembrada.
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final result = await LocalAuthService.login(
      _emailController.text,
      _passwordController.text,
      remember: _rememberAccess,
    );
    if (!mounted) return;
    if (!result.success) {
      setState(() => _errorMessage = result.message);
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    await Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _openForgotPassword() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) =>
            ForgotPasswordScreen(initialEmail: _emailController.text),
      ),
    );
    if (!mounted || email == null) return;
    setState(() {
      _emailController.text = email;
      _passwordController.clear();
      _errorMessage = null;
    });
  }

  void _openRegister() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: const AlugaPlayLogo(size: 84)),
                      const SizedBox(height: 18),
                      const Center(
                        child: AlugaPlayWordmark(
                          fontSize: 30,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bem-vindo! Acesse sua conta para explorar consoles, jogos físicos e pacotes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: _textPrimary.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroBannerGradient(
                            Theme.of(context).brightness,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.blueAccent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Entrar na plataforma',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                key: const ValueKey('login-email'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                validator: _validateEmail,
                                onChanged: (_) {
                                  if (_errorMessage != null) {
                                    setState(() => _errorMessage = null);
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  hintText: 'jogador@alugaplay.com',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const ValueKey('login-password'),
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Informe sua senha.'
                                    : null,
                                onFieldSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    tooltip: _obscurePassword
                                        ? 'Mostrar senha'
                                        : 'Ocultar senha',
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final rememberOption = Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: _rememberAccess,
                                        activeColor: AppTheme.blue,
                                        onChanged: (value) => setState(
                                          () =>
                                              _rememberAccess = value ?? false,
                                        ),
                                      ),
                                      Flexible(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _rememberAccess =
                                                !_rememberAccess,
                                          ),
                                          child: const Text(
                                            'Lembrar meu acesso',
                                            style: TextStyle(
                                              color: AppTheme.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                  final forgotPassword = TextButton(
                                    onPressed: _openForgotPassword,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.blue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text(
                                      'Esqueci minha senha',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  );
                                  if (constraints.maxWidth < 340) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        rememberOption,
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: forgotPassword,
                                        ),
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: rememberOption),
                                      forgotPassword,
                                    ],
                                  );
                                },
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _errorMessage!,
                                  key: const ValueKey('login-error'),
                                  style: TextStyle(
                                    color: colors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Entrar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Acesso local demonstrativo. Seus dados não são enviados a um servidor.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textPrimary.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: FittedBox(
                          key: const ValueKey('register-footer-line'),
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Não tem conta? ',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              Semantics(
                                link: true,
                                child: Material(
                                  color: _registerPressed
                                      ? AppTheme.gold.withValues(alpha: 0.16)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    key: const ValueKey(
                                      'register-account-link',
                                    ),
                                    onTap: _openRegister,
                                    onHighlightChanged: (highlighted) {
                                      setState(
                                        () => _registerPressed = highlighted,
                                      );
                                    },
                                    splashColor: AppTheme.blueAccent.withValues(
                                      alpha: 0.28,
                                    ),
                                    highlightColor: AppTheme.gold.withValues(
                                      alpha: 0.22,
                                    ),
                                    hoverColor: AppTheme.blue.withValues(
                                      alpha: 0.12,
                                    ),
                                    mouseCursor: SystemMouseCursors.click,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        'Criar nova conta',
                                        style: TextStyle(
                                          color: _registerPressed
                                              ? AppTheme.gold
                                              : AppTheme.blueAccent,
                                          fontWeight: FontWeight.w700,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
