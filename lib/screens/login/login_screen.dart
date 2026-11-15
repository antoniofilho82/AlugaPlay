import 'package:material_ui/material_ui.dart';

import '../../models/user_profile.dart';
import '../../routes/app_routes.dart';

/// Tela de entrada demonstrativa, sem autenticação ou serviço externo.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surface;
  Color get _surfaceContainer =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _accent => Theme.of(context).colorScheme.secondary;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;

  // Os controladores permitem ler os campos e precisam ser descartados no fim.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Alterna a visibilidade sem modificar o conteúdo digitado.
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Evita manter os controladores ativos após a saída da tela.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Encerra o teclado, atualiza o perfil demonstrativo e abre a Home.
  void _enterDemoMode() {
    // Fecha o teclado e aproveita o e-mail informado para personalizar o perfil.
    FocusScope.of(context).unfocus();
    UserProfile.updateFromLoginEmail(_emailController.text);
    ScaffoldMessenger.of(context).clearSnackBars();
    // A troca substitui o login para que o botão voltar não reabra essa tela.
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  /// Explica que recursos ainda não integrados não executam ações reais.
  void _showPrototypeNotice(String featureName) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$featureName estará disponível na etapa de integração com Firebase.',
            style: TextStyle(color: _textPrimary),
          ),
          backgroundColor: _surfaceContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // A rolagem permite usar o formulário mesmo com teclado ou tela compacta.
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
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
                        // Marca e chamada de entrada apresentam o propósito da tela.
                        Center(
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _accent.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.sports_esports_rounded,
                              size: 42,
                              color: _accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Aluga',
                                  style: TextStyle(color: _textPrimary),
                                ),
                                TextSpan(
                                  text: 'Play',
                                  style: TextStyle(color: _accent),
                                ),
                              ],
                            ),
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
                          // O formulário permanece contido num painel de contraste.
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _textPrimary.withValues(alpha: 0.08),
                            ),
                          ),
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
                              TextField(
                                // Campo de sessão usado para compor o perfil demonstrativo.
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(color: _textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'E-mail',
                                  hintText: 'jogador@alugaplay.com',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: _accent,
                                  ),
                                  filled: true,
                                  fillColor: _background,
                                  labelStyle: TextStyle(
                                    color: _textPrimary.withValues(alpha: 0.75),
                                  ),
                                  hintStyle: TextStyle(
                                    color: _textPrimary.withValues(alpha: 0.4),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _textPrimary.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _accent,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                // A senha é apenas visual nesta etapa, sem validação remota.
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _enterDemoMode(),
                                style: TextStyle(color: _textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  hintText: '••••••••',
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: _accent,
                                  ),
                                  suffixIcon: IconButton(
                                    // O estado controla o ícone e a ocultação do texto.
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    tooltip: _obscurePassword
                                        ? 'Mostrar senha'
                                        : 'Ocultar senha',
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _accent,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: _background,
                                  labelStyle: TextStyle(
                                    color: _textPrimary.withValues(alpha: 0.75),
                                  ),
                                  hintStyle: TextStyle(
                                    color: _textPrimary.withValues(alpha: 0.4),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _textPrimary.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _accent,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _showPrototypeNotice(
                                    'Recuperação de senha',
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _accent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: const Text(
                                    'Esqueci minha senha',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  // O acesso demonstrativo encaminha diretamente ao catálogo.
                                  onPressed: _enterDemoMode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: _textPrimary,
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
                                'Protótipo demonstrativo: toque em Entrar para acessar o catálogo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textPrimary.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          // Wrap permite que os textos de cadastro quebrem em telas estreitas.
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Ainda não tem conta?',
                              style: TextStyle(
                                fontSize: 14,
                                color: _textPrimary.withValues(alpha: 0.75),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _showPrototypeNotice('Criação de conta'),
                              style: TextButton.styleFrom(
                                foregroundColor: _accent,
                              ),
                              child: const Text(
                                'Criar conta',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
