/// Guarda os dados de exibição da sessão demonstrativa atual.
class UserProfile {
  /// Mantém os valores do perfil imutáveis após sua criação.
  const UserProfile({
    required this.displayName,
    required this.email,
    required this.gamerTag,
    required this.city,
    required this.accountBadge,
  });

  /// Nome amigável mostrado na área de perfil.
  final String displayName;

  /// E-mail informado na entrada demonstrativa.
  final String email;

  /// Identificador gamer derivado do nome local do e-mail.
  final String gamerTag;

  /// Localização demonstrativa da conta.
  final String city;

  /// Selo que identifica a natureza de protótipo da conta.
  final String accountBadge;

  /// Valores usados quando ainda não foi informado um e-mail de sessão.
  static const UserProfile defaultProfile = UserProfile(
    displayName: 'Jogador AlugaPlay',
    email: 'jogador@alugaplay.com',
    gamerTag: '@alugaplayer',
    city: 'Teresina, PI',
    accountBadge: 'Conta Gamer Demonstrativa',
  );

  /// Perfil mutável da sessão atual; não é persistido fora da memória.
  static UserProfile currentUser = defaultProfile;

  /// Usa o nome local do e-mail para criar uma identificação amigável.
  static void updateFromLoginEmail(String rawEmail) {
    final email = rawEmail.trim();
    if (email.isEmpty) {
      currentUser = defaultProfile;
      return;
    }

    // Troca separadores comuns por espaços antes de capitalizar cada trecho.
    final localPart = email.split('@').first;
    final displayName = localPart
        .replaceAll(RegExp(r'[._]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');

    currentUser = UserProfile(
      displayName: displayName.isEmpty
          ? defaultProfile.displayName
          : displayName,
      email: email,
      gamerTag: '@${localPart.toLowerCase()}',
      city: defaultProfile.city,
      accountBadge: defaultProfile.accountBadge,
    );
  }

  /// Restaura os dados demonstrativos padrão ao encerrar a sessão.
  static void reset() {
    currentUser = defaultProfile;
  }
}
