import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _subscriptionStatusKey = 'subscription_status';

  final SharedPreferences _prefs;

  SecureStorage(this._prefs);

  // Factory method to initialize
  static Future<SecureStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SecureStorage(prefs);
  }

  // Access Token
  Future<void> saveAccessToken(String token) async {
    await _prefs.setString(_accessTokenKey, token);
  }

  String? getAccessToken() {
    return _prefs.getString(_accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await _prefs.remove(_accessTokenKey);
  }

  // Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshTokenKey, token);
  }

  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _prefs.remove(_refreshTokenKey);
  }

  // User Data (JSON string)
  Future<void> saveUserData(String userData) async {
    await _prefs.setString(_userDataKey, userData);
  }

  String? getUserData() {
    return _prefs.getString(_userDataKey);
  }

  Future<void> deleteUserData() async {
    await _prefs.remove(_userDataKey);
  }

  // Subscription Status
  Future<void> saveSubscriptionStatus(String status) async {
    await _prefs.setString(_subscriptionStatusKey, status);
  }

  String? getSubscriptionStatus() {
    return _prefs.getString(_subscriptionStatusKey);
  }

  Future<void> deleteSubscriptionStatus() async {
    await _prefs.remove(_subscriptionStatusKey);
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
      deleteUserData(),
      deleteSubscriptionStatus(),
    ]);
  }
}
