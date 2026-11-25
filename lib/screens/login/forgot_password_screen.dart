import 'package:material_ui/material_ui.dart';

import '../../components/alugaplay_logo.dart';
import '../../services/local_auth_service.dart';
import '../../theme/app_theme.dart';

/// Recupera uma senha local em duas etapas, sem envio de mensagens externas.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _verified = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _errorMessage;

  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _verifyEmail() {
    FocusScope.of(context).unfocus();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(_emailController.text.trim())) {
      setState(() => _errorMessage = 'Informe um e-mail válido.');
      return;
    }
    if (!LocalAuthService.emailExists(_emailController.text)) {
      setState(
        () => _errorMessage = 'Não encontramos uma conta com este e-mail.',
      );
      return;
    }
    setState(() {
      _verified = true;
      _errorMessage = null;
    });
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final result = await LocalAuthService.resetPassword(
      email,
      _passwordController.text,
    );
    if (!mounted) return;
    if (!result.success) {
      setState(() => _errorMessage = result.message);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message)));
    Navigator.of(context).pop(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Senha')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroBannerGradient(
                    Theme.of(context).brightness,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.blueAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AlugaPlayLogo(size: 72)),
                    const SizedBox(height: 18),
                    Text(
                      'Redefina sua senha',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A recuperação é feita localmente para contas cadastradas neste dispositivo.',
                      style: TextStyle(
                        color: _textPrimary.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const ValueKey('forgot-email'),
                      controller: _emailController,
                      enabled: !_verified,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail cadastrado',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    if (_verified) ...[
                      const SizedBox(height: 14),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              key: const ValueKey('forgot-password'),
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: (value) =>
                                  value == null || value.length < 6
                                  ? 'A senha deve ter pelo menos 6 caracteres.'
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Nova senha',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
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
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const ValueKey('forgot-confirm-password'),
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmation,
                              validator: (value) =>
                                  value != _passwordController.text
                                  ? 'As senhas não coincidem.'
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Confirmar nova senha',
                                prefixIcon: const Icon(
                                  Icons.lock_reset_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscureConfirmation =
                                        !_obscureConfirmation,
                                  ),
                                  tooltip: _obscureConfirmation
                                      ? 'Mostrar senha'
                                      : 'Ocultar senha',
                                  icon: Icon(
                                    _obscureConfirmation
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        key: const ValueKey('forgot-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _verified ? _resetPassword : _verifyEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _verified ? 'Redefinir senha' : 'Verificar e-mail',
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
    );
  }
}
