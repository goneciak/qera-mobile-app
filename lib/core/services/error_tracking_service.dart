import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ErrorTrackingService {
  /// Capture exception with context
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
    Map<String, dynamic>? extras,
  }) async {
    try {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: hint != null ? Hint.withMap({'message': hint}) : null,
        withScope: (scope) {
          if (extras != null) {
            extras.forEach((key, value) {
              scope.setExtra(key, value);
            });
          }
        },
      );
      print('🐛 Exception captured by Sentry: $exception');
    } catch (e) {
      print('❌ Error capturing exception: $e');
    }
  }

  /// Capture message (info/warning)
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extras,
  }) async {
    try {
      await Sentry.captureMessage(
        message,
        level: level,
        withScope: (scope) {
          if (extras != null) {
            extras.forEach((key, value) {
              scope.setExtra(key, value);
            });
          }
        },
      );
      print('🐛 Message captured by Sentry: $message');
    } catch (e) {
      print('❌ Error capturing message: $e');
    }
  }

  /// Add breadcrumb (for debugging context)
  static void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    try {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          data: data,
          level: level,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print('❌ Error adding breadcrumb: $e');
    }
  }

  /// Set user context
  static Future<void> setUser({
    required String id,
    String? email,
    String? username,
    Map<String, dynamic>? extras,
  }) async {
    try {
      await Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: id,
          email: email,
          username: username,
          data: extras,
        ));
      });
    } catch (e) {
      print('❌ Error setting user: $e');
    }
  }

  /// Clear user context
  static Future<void> clearUser() async {
    try {
      await Sentry.configureScope((scope) {
        scope.setUser(null);
      });
    } catch (e) {
      print('❌ Error clearing user: $e');
    }
  }

  /// Set custom tag
  static void setTag(String key, String value) {
    try {
      Sentry.configureScope((scope) {
        scope.setTag(key, value);
      });
    } catch (e) {
      print('❌ Error setting tag: $e');
    }
  }

  /// Set custom context
  static void setContext(String key, Map<String, dynamic> value) {
    try {
      Sentry.configureScope((scope) {
        scope.setContexts(key, value);
      });
    } catch (e) {
      print('❌ Error setting context: $e');
    }
  }

  /// Track API error
  static Future<void> trackApiError({
    required String endpoint,
    required int statusCode,
    required String method,
    String? errorMessage,
  }) async {
    await captureMessage(
      'API Error: $method $endpoint - $statusCode',
      level: SentryLevel.error,
      extras: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'method': method,
        'error_message': errorMessage ?? 'Unknown error',
      },
    );
  }

  /// Track business logic error
  static Future<void> trackBusinessError({
    required String operation,
    required String error,
    Map<String, dynamic>? context,
  }) async {
    await captureMessage(
      'Business Error: $operation - $error',
      level: SentryLevel.warning,
      extras: {
        'operation': operation,
        'error': error,
        ...?context,
      },
    );
  }
}

// Riverpod provider
final errorTrackingServiceProvider = Provider<ErrorTrackingService>((ref) {
  return ErrorTrackingService();
});
