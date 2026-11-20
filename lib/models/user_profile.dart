/// Guarda os dados de exibição da sessão demonstrativa atual.
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.email,
    required this.gamerTag,
    this.city = '',
    required this.phone,
    required this.accountBadge,
    this.address = '',
    this.cpf = '',
    this.profileImagePath,
  });

  final String displayName;

  final String email;

  final String gamerTag;

  final String city;

  final String phone;

  final String address;

  final String cpf;

  /// Caminho local da foto; avatar usa a inicial se estiver ausente ou inválido.
  final String? profileImagePath;

  bool get hasProfileImage =>
      profileImagePath != null && profileImagePath!.trim().isNotEmpty;

  String? get normalizedProfileImagePath =>
      hasProfileImage ? profileImagePath!.trim() : null;

  final String accountBadge;

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'email': email,
    'gamerTag': gamerTag,
    'city': city,
    'phone': phone,
    'address': address,
    'cpf': cpf,
    'profileImagePath': profileImagePath,
    'accountBadge': accountBadge,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    displayName: json['displayName'] as String,
    email: json['email'] as String,
    gamerTag: json['gamerTag'] as String,
    city: json['city'] as String? ?? '',
    phone: json['phone'] as String,
    address: json['address'] as String? ?? '',
    cpf: json['cpf'] as String? ?? '',
    profileImagePath: json['profileImagePath'] as String?,
    accountBadge:
        json['accountBadge'] as String? ?? defaultProfile.accountBadge,
  );

  static const UserProfile defaultProfile = UserProfile(
    displayName: 'Jogador AlugaPlay',
    email: 'jogador@alugaplay.com',
    gamerTag: '@alugaplayer',
    city: 'Teresina, PI',
    phone: '(86) 99999-0000',
    accountBadge: 'Conta Gamer Demonstrativa',
  );

  /// Snapshot ativo em memória; o serviço de autenticação também o persiste.
  static UserProfile currentUser = defaultProfile;

  /// Preferências em memória, serializadas pelo serviço de autenticação.
  static String defaultDeliveryMethod = 'Retirada na Loja';
  static int defaultRentalDays = 3;
  static String favoritePlatform = 'Todas';
  static bool notifyReturnReminder = true;
  static bool notifyNewReleases = true;

  /// Atualiza os dados editáveis do jogador sem perder os dados da sessão.
  static void updatePlayerDetails({
    required String displayName,
    required String phone,
    required String cpf,
    required String? profileImagePath,
    String? city,
    String? address,
  }) {
    currentUser = currentUser.copyWith(
      displayName: displayName.trim().isEmpty
          ? defaultProfile.displayName
          : displayName.trim(),
      phone: phone.trim(),
      cpf: cpf.trim(),
      city: city?.trim(),
      address: address,
      profileImagePath: profileImagePath,
      clearProfileImage: profileImagePath == null,
    );
  }

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
      phone: defaultProfile.phone,
      accountBadge: defaultProfile.accountBadge,
    );
  }

  /// Restaura o perfil e as preferências demonstrativas padrão.
  static void resetToDefaults() {
    currentUser = defaultProfile;
    defaultDeliveryMethod = 'Retirada na Loja';
    defaultRentalDays = 3;
    favoritePlatform = 'Todas';
    notifyReturnReminder = true;
    notifyNewReleases = true;
  }

  static void reset() {
    resetToDefaults();
  }

  /// Cria uma cópia com os campos pessoais alterados.
  UserProfile copyWith({
    String? displayName,
    String? email,
    String? gamerTag,
    String? city,
    String? phone,
    String? address,
    String? cpf,
    String? profileImagePath,
    bool clearProfileImage = false,
    String? accountBadge,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      gamerTag: gamerTag ?? this.gamerTag,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      cpf: cpf ?? this.cpf,
      profileImagePath: clearProfileImage
          ? null
          : profileImagePath ?? this.profileImagePath,
      accountBadge: accountBadge ?? this.accountBadge,
    );
  }
}
