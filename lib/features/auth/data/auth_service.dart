import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';
import '../models/login_models.dart';

class AuthService {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  AuthService(this._apiClient, this._storage);

  /// Login with email and password
  Future<UserModel> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: LoginRequest(email: email, password: password).toJson(),
    );

    final loginResponse = LoginResponse.fromJson(response.data);
    
    // Save tokens
    await _storage.saveAccessToken(loginResponse.accessToken);
    await _storage.saveRefreshToken(loginResponse.refreshToken);

    // Fetch user data from /auth/me
    final user = await getCurrentUser();
    
    // Save user data
    await _storage.saveUserData(jsonEncode(user.toJson()));

    return user;
  }

  /// Get current user from /auth/me
  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data);
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      await _storage.clearAll();
    }
  }

  /// Request password reset
  Future<void> requestPasswordReset(String email) async {
    await _apiClient.post(
      ApiEndpoints.passwordResetRequest,
      data: {'email': email},
    );
  }

  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiEndpoints.passwordResetConfirm,
      data: {
        'token': token,
        'newPassword': newPassword,
      },
    );
  }

  /// Accept invite
  Future<UserModel> acceptInvite({
    required String token,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.acceptInvite,
      data: {
        'token': token,
        'password': password,
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    final loginResponse = LoginResponse.fromJson(response.data);

    // Save tokens
    await _storage.saveAccessToken(loginResponse.accessToken);
    await _storage.saveRefreshToken(loginResponse.refreshToken);

    // Fetch user data from /auth/me
    final user = await getCurrentUser();

    // Save user data
    await _storage.saveUserData(jsonEncode(user.toJson()));

    return user;
  }

  /// Check if user is logged in (has valid token)
  bool isLoggedIn() {
    final token = _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get cached user data
  UserModel? getCachedUser() {
    final userDataString = _storage.getUserData();
    if (userDataString == null) return null;
    
    try {
      final userJson = jsonDecode(userDataString) as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } catch (e) {
      return null;
    }
  }
}
