import 'package:material_ui/material_ui.dart';

import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import 'local_storage_service.dart';

/// Resultado de uma operação de autenticação local.
class LocalAuthResult {
  const LocalAuthResult({required this.success, required this.message});

  final bool success;
  final String message;
}

/// Conta local serializada pelo serviço de armazenamento.
class LocalAuthUser {
  const LocalAuthUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.address,
    this.cpf = '',
    required this.password,
    this.isKycVerified = false,
    this.profileImagePath,
  });

  final String name;
  final String email;
  final String phone;
  final String city;
  final String address;
  final String cpf;
  // A senha fica no registro local para autenticação demonstrativa; não é cifrada.
  final String password;

  /// Campo de estado demonstrativo; o app não executa uma verificação KYC.
  final bool isKycVerified;
  final String? profileImagePath;

  // O JSON da conta contém a senha; o objeto de sessão nunca a inclui.
  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'city': city,
    'address': address,
    'cpf': cpf,
    'password': password,
    'isKycVerified': isKycVerified,
    'profileImagePath': profileImagePath,
  };

  factory LocalAuthUser.fromJson(Map<String, dynamic> json) => LocalAuthUser(
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    city: json['city'] as String? ?? '',
    address: json['address'] as String? ?? '',
    cpf: json['cpf'] as String? ?? '',
    password: json['password'] as String,
    isKycVerified: json['isKycVerified'] as bool? ?? false,
    profileImagePath: json['profileImagePath'] as String?,
  );
}

/// Autenticação local demonstrativa persistida no armazenamento do aparelho.
class LocalAuthService {
  LocalAuthService._();

  static const String invalidCredentialsMessage =
      'E-mail ou senha inválidos. Verifique seus dados ou crie uma conta.';

  static final Map<String, LocalAuthUser> _users = {};

  static bool rememberAccess = false;
  static String? rememberedEmail;
  static String? currentUserEmail;
  static LocalAuthUser? currentUser;

  /// Só permite pular o login quando a sessão e a conta foram restauradas.
  static bool get shouldAutoLogin => rememberAccess && currentUser != null;

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static bool emailExists(String email) =>
      _users.containsKey(_normalizeEmail(email));

  static Future<LocalAuthResult> login(
    String email,
    String password, {
    bool remember = false,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final user = _users[normalizedEmail];
    if (user == null || user.password != password) {
      return const LocalAuthResult(
        success: false,
        message: invalidCredentialsMessage,
      );
    }

    currentUser = user;
    currentUserEmail = user.email;
    UserProfile.currentUser = UserProfile.defaultProfile.copyWith(
      displayName: user.name,
      email: user.email,
      gamerTag: '@${user.email.split('@').first}',
      city: user.city,
      phone: user.phone,
      address: user.address,
      cpf: user.cpf,
      profileImagePath: user.profileImagePath,
    );
    rememberAccess = remember;
    if (remember) {
      rememberedEmail = user.email;
    } else {
      rememberedEmail = null;
    }

    // A sessão guarda somente o e-mail e a opção; a senha não é pré-preenchida.
    await _persistState();
    return const LocalAuthResult(
      success: true,
      message: 'Acesso realizado com sucesso.',
    );
  }

  static Future<LocalAuthResult> register({
    required String name,
    required String email,
    required String phone,
    String city = '',
    String address = '',
    String cpf = '',
    required String password,
    bool remember = true,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (name.trim().isEmpty ||
        phone.trim().isEmpty ||
        !_isValidEmail(normalizedEmail) ||
        password.length < 6 ||
        (cpf.trim().isNotEmpty && !isValidCpf(cpf))) {
      return const LocalAuthResult(
        success: false,
        message: 'Confira os dados informados e use uma senha com 6 caracteres ou mais.',
      );
    }
    if (_users.containsKey(normalizedEmail)) {
      return const LocalAuthResult(
        success: false,
        message: 'Já existe uma conta cadastrada com este e-mail.',
      );
    }

    _users[normalizedEmail] = LocalAuthUser(
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      city: city.trim(),
      address: address.trim(),
      cpf: cpf.trim(),
      password: password,
    );
    return login(normalizedEmail, password, remember: remember);
  }

  static Future<LocalAuthResult> resetPassword(
    String email,
    String newPassword,
  ) async {
    final normalizedEmail = _normalizeEmail(email);
    final user = _users[normalizedEmail];
    if (user == null) {
      return const LocalAuthResult(
        success: false,
        message: 'Não encontramos uma conta com este e-mail.',
      );
    }
    if (newPassword.length < 6) {
      return const LocalAuthResult(
        success: false,
        message: 'A senha deve ter pelo menos 6 caracteres.',
      );
    }

    _users[normalizedEmail] = LocalAuthUser(
      name: user.name,
      email: user.email,
      phone: user.phone,
      city: user.city,
      address: user.address,
      cpf: user.cpf,
      password: newPassword,
      isKycVerified: user.isKycVerified,
      profileImagePath: user.profileImagePath,
    );
    await _persistState();
    return const LocalAuthResult(
      success: true,
      message: 'Senha redefinida com sucesso.',
    );
  }

  static Future<void> logout() async {
    currentUser = null;
    currentUserEmail = null;
    rememberAccess = false;
    rememberedEmail = null;
    UserProfile.currentUser = UserProfile.defaultProfile;
    // As contas e os aluguéis permanecem; apenas a sessão autenticada é removida.
    await _persistState(persistSession: false);
    await LocalStorageService.clearSession();
  }

  static Future<bool> updateCurrentUserProfile({
    required String name,
    required String phone,
    required String cpf,
    required String? profileImagePath,
    String? city,
    String? address,
  }) async {
    final user = currentUser;
    if (user == null || (cpf.trim().isNotEmpty && !isValidCpf(cpf))) {
      return false;
    }

    final updatedUser = LocalAuthUser(
      name: name.trim().isEmpty ? user.name : name.trim(),
      email: user.email,
      phone: phone.trim(),
      city: city?.trim() ?? user.city,
      address: address?.trim() ?? user.address,
      cpf: cpf.trim(),
      password: user.password,
      isKycVerified: user.isKycVerified,
      profileImagePath: profileImagePath,
    );
    _users[user.email] = updatedUser;
    currentUser = updatedUser;
    UserProfile.updatePlayerDetails(
      displayName: updatedUser.name,
      phone: updatedUser.phone,
      cpf: updatedUser.cpf,
      profileImagePath: profileImagePath,
      city: city,
      address: address,
    );
    await _persistState();
    return true;
  }

  static Future<void> clearAllForTest() async {
    clearInMemoryForTest();
    await LocalStorageService.clearAll();
  }

  static void clearInMemoryForTest() {
    _users.clear();
    rememberAccess = false;
    rememberedEmail = null;
    currentUserEmail = null;
    currentUser = null;
    UserProfile.resetToDefaults();
  }

  /// Reconstitui conta, sessão, perfil e preferências antes do auto-login.
  static Future<void> restoreFromStorage() async {
    _users
      ..clear()
      ..addEntries(
        LocalStorageService.loadUsers().map((json) {
          final user = LocalAuthUser.fromJson(json);
          return MapEntry(_normalizeEmail(user.email), user);
        }),
      );

    final session = LocalStorageService.loadSession() ?? {};
    rememberAccess = session['rememberAccess'] as bool? ?? false;
    rememberedEmail = rememberAccess
        ? session['rememberedEmail'] as String?
        : null;
    currentUserEmail = rememberAccess
        ? session['currentUserEmail'] as String?
        : null;
    currentUser = currentUserEmail == null
        ? null
        : _users[_normalizeEmail(currentUserEmail!)];
    if (currentUser == null) {
      rememberAccess = false;
      rememberedEmail = null;
      currentUserEmail = null;
    }

    final profile = LocalStorageService.loadProfile();
    if (profile != null) {
      UserProfile.currentUser = UserProfile.fromJson(profile);
    } else if (currentUser != null) {
      final user = currentUser!;
      UserProfile.currentUser = UserProfile.defaultProfile.copyWith(
        displayName: user.name,
        email: user.email,
        gamerTag: '@${user.email.split('@').first}',
        city: user.city,
        phone: user.phone,
        address: user.address,
        cpf: user.cpf,
        profileImagePath: user.profileImagePath,
      );
    } else {
      UserProfile.currentUser = UserProfile.defaultProfile;
    }

    final preferences = LocalStorageService.loadPreferences();
    UserProfile.defaultDeliveryMethod =
        preferences['defaultDeliveryMethod'] as String? ?? 'Retirada na Loja';
    UserProfile.defaultRentalDays =
        preferences['defaultRentalDays'] as int? ?? 3;
    UserProfile.favoritePlatform =
        preferences['favoritePlatform'] as String? ?? 'Todas';
    final notificationsEnabled =
        preferences['notificationsEnabled'] as bool? ?? true;
    UserProfile.notifyReturnReminder = notificationsEnabled;
    UserProfile.notifyNewReleases = notificationsEnabled;
    AppTheme.themeModeNotifier.value = switch (preferences['themeMode']) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  static Future<void> persistPreferences() =>
      LocalStorageService.savePreferences(_preferencesJson());

  static Future<void> _persistState({bool persistSession = true}) async {
    await LocalStorageService.saveUsers(
      _users.values.map((user) => user.toJson()).toList(),
    );
    if (persistSession) {
      await LocalStorageService.saveSession({
        'rememberAccess': rememberAccess,
        'rememberedEmail': rememberedEmail,
        'currentUserEmail': currentUserEmail,
      });
    }
    await LocalStorageService.saveProfile(UserProfile.currentUser.toJson());
    await LocalStorageService.savePreferences(_preferencesJson());
  }

  static Map<String, dynamic> _preferencesJson() => {
    'themeMode': switch (AppTheme.themeModeNotifier.value) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    },
    'notificationsEnabled':
        UserProfile.notifyReturnReminder && UserProfile.notifyNewReleases,
    'defaultDeliveryMethod': UserProfile.defaultDeliveryMethod,
    'defaultRentalDays': UserProfile.defaultRentalDays,
    'favoritePlatform': UserProfile.favoritePlatform,
  };

  static bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  /// Valida os dígitos verificadores locais e rejeita sequências repetidas.
  static bool isValidCpf(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(digits)) {
      return false;
    }

    int verifierFor(int digitCount) {
      var sum = 0;
      for (var index = 0; index < digitCount; index++) {
        sum += int.parse(digits[index]) * (digitCount + 1 - index);
      }
      final remainder = sum % 11;
      return remainder < 2 ? 0 : 11 - remainder;
    }

    return int.parse(digits[9]) == verifierFor(9) &&
        int.parse(digits[10]) == verifierFor(10);
  }
}
