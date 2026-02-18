import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      print('📊 Screen view logged: $screenName');
    } catch (e) {
      print('❌ Error logging screen view: $e');
    }
  }

  /// Log custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      print('📊 Event logged: $name ${parameters ?? ""}');
    } catch (e) {
      print('❌ Error logging event: $e');
    }
  }

  /// Log interview created
  Future<void> logInterviewCreated({
    required String interviewId,
    required String status,
  }) async {
    await logEvent(
      name: 'interview_created',
      parameters: {
        'interview_id': interviewId,
        'status': status,
      },
    );
  }

  /// Log interview submitted
  Future<void> logInterviewSubmitted({
    required String interviewId,
  }) async {
    await logEvent(
      name: 'interview_submitted',
      parameters: {'interview_id': interviewId},
    );
  }

  /// Log offer generated
  Future<void> logOfferGenerated({
    required String offerId,
    required String interviewId,
    required double totalPrice,
  }) async {
    await logEvent(
      name: 'offer_generated',
      parameters: {
        'offer_id': offerId,
        'interview_id': interviewId,
        'total_price': totalPrice,
      },
    );
  }

  /// Log offer sent
  Future<void> logOfferSent({
    required String offerId,
  }) async {
    await logEvent(
      name: 'offer_sent',
      parameters: {'offer_id': offerId},
    );
  }

  /// Log commission earned
  Future<void> logCommissionEarned({
    required String commissionId,
    required double amount,
  }) async {
    await logEvent(
      name: 'commission_earned',
      parameters: {
        'commission_id': commissionId,
        'amount': amount,
      },
    );
  }

  /// Log file upload
  Future<void> logFileUpload({
    required String fileType,
    required int fileSize,
  }) async {
    await logEvent(
      name: 'file_upload',
      parameters: {
        'file_type': fileType,
        'file_size': fileSize,
      },
    );
  }

  /// Log PDF generation
  Future<void> logPdfGenerated({
    required String documentType,
  }) async {
    await logEvent(
      name: 'pdf_generated',
      parameters: {'document_type': documentType},
    );
  }

  /// Log e-signature created
  Future<void> logEsignCreated({
    required String envelopeId,
    required String provider,
  }) async {
    await logEvent(
      name: 'esign_created',
      parameters: {
        'envelope_id': envelopeId,
        'provider': provider,
      },
    );
  }

  /// Log user login
  Future<void> logLogin({
    required String method,
  }) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Log user signup
  Future<void> logSignUp({
    required String method,
  }) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}

// Riverpod provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
