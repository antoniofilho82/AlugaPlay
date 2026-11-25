import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Armazena snapshots JSON no aparelho por meio de `shared_preferences`.
class LocalStorageService {
  LocalStorageService._();

  static const _usersKey = 'alugaplay.users';
  static const _sessionKey = 'alugaplay.session';
  static const _profileKey = 'alugaplay.profile';
  static const _preferencesKey = 'alugaplay.preferences';
  static const _rentalsKey = 'alugaplay.rentals';

  static SharedPreferences? _preferences;

  /// Obtém a instância única usada pelas leituras e gravações locais.
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static List<Map<String, dynamic>> loadUsers() => _loadList(_usersKey);

  static Map<String, dynamic>? loadSession() => _loadMap(_sessionKey);

  static Map<String, dynamic>? loadProfile() => _loadMap(_profileKey);

  static Map<String, dynamic> loadPreferences() =>
      _loadMap(_preferencesKey) ?? {};

  static List<Map<String, dynamic>> loadRentals() => _loadList(_rentalsKey);

  static Future<void> saveUsers(List<Map<String, dynamic>> users) =>
      _save(_usersKey, users);

  static Future<void> saveSession(Map<String, dynamic> session) =>
      _save(_sessionKey, session);

  static Future<void> clearSession() async {
    if (!await _instance.remove(_sessionKey)) {
      throw StateError('Não foi possível limpar a sessão local.');
    }
  }

  static Future<void> saveProfile(Map<String, dynamic> profile) =>
      _save(_profileKey, profile);

  static Future<void> savePreferences(Map<String, dynamic> preferences) =>
      _save(_preferencesKey, preferences);

  static Future<void> saveRentals(List<Map<String, dynamic>> rentals) =>
      _save(_rentalsKey, rentals);

  static Future<void> clearAll() async {
    if (!await _instance.clear()) {
      throw StateError('Não foi possível limpar o armazenamento local.');
    }
  }

  static List<Map<String, dynamic>> _loadList(String key) {
    final value = _instance.getString(key);
    if (value == null) return [];
    // Erros de JSON ou formato são propagados para não ocultar dados inválidos.
    final decoded = jsonDecode(value);
    if (decoded is! List) {
      throw FormatException('O valor armazenado em $key não é uma lista.');
    }
    return decoded.map((item) {
      if (item is! Map) {
        throw FormatException('Um item armazenado em $key não é um objeto.');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  static Map<String, dynamic>? _loadMap(String key) {
    final value = _instance.getString(key);
    if (value == null) return null;
    // Não substitui silenciosamente um objeto corrompido por valores padrão.
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw FormatException('O valor armazenado em $key não é um objeto.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static Future<void> _save(String key, Object value) async {
    if (!await _instance.setString(key, jsonEncode(value))) {
      throw StateError('Não foi possível salvar $key no armazenamento local.');
    }
  }

  static SharedPreferences get _instance {
    final preferences = _preferences;
    if (preferences == null) {
      throw StateError('LocalStorageService.init() ainda não foi chamado.');
    }
    return preferences;
  }
}
