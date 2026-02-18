import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorage _storage;
  final Logger _logger = Logger();
  bool _isRefreshing = false;

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Client-Type': 'mobile',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add access token to headers
          final token = _storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // Detailed request logging
          _logger.i('┌─────────────────────────────────────────────────────────');
          _logger.i('│ 📤 REQUEST [${options.method}]');
          _logger.i('│ URL: ${options.baseUrl}${options.path}');
          _logger.i('│ Headers: ${options.headers}');
          if (options.queryParameters.isNotEmpty) {
            _logger.i('│ Query Parameters: ${options.queryParameters}');
          }
          if (options.data != null) {
            _logger.i('│ Body: ${options.data}');
          }
          _logger.i('└─────────────────────────────────────────────────────────');
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Detailed response logging
          _logger.i('┌─────────────────────────────────────────────────────────');
          _logger.i('│ 📥 RESPONSE [${response.statusCode}]');
          _logger.i('│ URL: ${response.requestOptions.path}');
          _logger.i('│ Headers: ${response.headers}');
          _logger.i('│ Body: ${response.data}');
          _logger.i('└─────────────────────────────────────────────────────────');
          
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Detailed error logging
          _logger.e('┌─────────────────────────────────────────────────────────');
          _logger.e('│ ❌ ERROR [${error.response?.statusCode}]');
          _logger.e('│ URL: ${error.requestOptions.path}');
          _logger.e('│ Message: ${error.message}');
          if (error.response?.data != null) {
            _logger.e('│ Response: ${error.response?.data}');
          }
          _logger.e('└─────────────────────────────────────────────────────────');

          // Ignore 400/404 errors for frontend-only routes (like /interviews/create)
          final path = error.requestOptions.path;
          if ((error.response?.statusCode == 400 || error.response?.statusCode == 404) && 
              (path.contains('/create') || path.contains('/edit'))) {
            _logger.w('Ignoring error for frontend route: $path');
            return handler.next(error);
          }

          // Handle 401 Unauthorized - try to refresh token
          // Skip refresh for auth endpoints where 401 means invalid credentials
          final isAuthEndpoint = path.contains('/auth/login') || 
                                  path.contains('/auth/invite/accept') ||
                                  path.contains('/auth/refresh');
          if (error.response?.statusCode == 401 && !_isRefreshing && !isAuthEndpoint) {
            _logger.w('Token expired, attempting refresh...');
            
            final refreshed = await _refreshToken();
            
            if (refreshed) {
              // Retry the original request with new token
              try {
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                );
                final token = _storage.getAccessToken();
                if (token != null) {
                  opts.headers?['Authorization'] = 'Bearer $token';
                }
                
                final cloneReq = await _dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                
                return handler.resolve(cloneReq);
              } catch (e) {
                return handler.next(error);
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Refresh the access token using refresh token
  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    
    _isRefreshing = true;
    
    try {
      final refreshToken = _storage.getRefreshToken();
      if (refreshToken == null) {
        _logger.w('No refresh token available');
        _isRefreshing = false;
        return false;
      }

      _logger.d('Refreshing token...');
      
      // Create a new Dio instance without interceptors for refresh request
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'] as String?;
      final newRefreshToken = response.data['refreshToken'] as String?;

      if (newAccessToken != null) {
        await _storage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await _storage.saveRefreshToken(newRefreshToken);
        }
        _logger.d('Token refreshed successfully');
        _isRefreshing = false;
        return true;
      }

      _isRefreshing = false;
      return false;
    } catch (e) {
      _logger.e('Token refresh failed: $e');
      _isRefreshing = false;
      // Clear tokens on refresh failure
      await _storage.clearAll();
      return false;
    }
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Upload file
  Future<Response> uploadFile(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        ...?data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    String errorMessage = 'Wystąpił błąd';

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Przekroczono limit czasu połączenia';
    } else if (error.type == DioExceptionType.connectionError) {
      errorMessage = 'Brak połączenia z internetem';
    } else if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      switch (statusCode) {
        case 400:
          // NestJS zwraca błędy walidacji jako array w "message"
          if (data is Map<String, dynamic> && data['message'] != null) {
            final message = data['message'];
            
            // Jeśli message to lista błędów walidacji
            if (message is List) {
              errorMessage = 'Błąd walidacji:\n${message.join('\n')}';
            } 
            // Jeśli message to mapa błędów (np. z class-validator)
            else if (message is Map) {
              final errors = <String>[];
              message.forEach((key, value) {
                if (value is List) {
                  errors.add('$key: ${value.join(', ')}');
                } else {
                  errors.add('$key: $value');
                }
              });
              errorMessage = 'Błąd walidacji:\n${errors.join('\n')}';
            }
            // Jeśli message to string
            else {
              errorMessage = message.toString();
            }
          } else {
            errorMessage = 'Nieprawidłowe dane';
          }
          break;
        case 401:
          errorMessage = 'Sesja wygasła. Zaloguj się ponownie';
          break;
        case 403:
          errorMessage = 'Brak dostępu';
          break;
        case 404:
          errorMessage = 'Nie znaleziono';
          break;
        case 422:
          // Unprocessable Entity - również błędy walidacji
          if (data is Map<String, dynamic> && data['message'] != null) {
            final message = data['message'];
            if (message is List) {
              errorMessage = 'Błąd walidacji:\n${message.join('\n')}';
            } else if (message is Map) {
              final errors = <String>[];
              message.forEach((key, value) {
                if (value is List) {
                  errors.add('$key: ${value.join(', ')}');
                } else {
                  errors.add('$key: $value');
                }
              });
              errorMessage = 'Błąd walidacji:\n${errors.join('\n')}';
            } else {
              errorMessage = message.toString();
            }
          } else {
            errorMessage = 'Błąd walidacji';
          }
          break;
        case 500:
          errorMessage = 'Błąd serwera';
          break;
        default:
          errorMessage = data['message'] ?? 'Wystąpił błąd';
      }
    }

    return errorMessage;
  }
}
