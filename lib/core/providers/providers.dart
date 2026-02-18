import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/account/data/subscription_service.dart';
import '../../features/interviews/data/interview_service.dart';
import '../../features/documents/data/document_service.dart';
import '../../features/offers/data/offer_service.dart';
import '../../features/esign/data/esign_service.dart';
import '../../features/files/data/file_service.dart';
import '../../features/ocr/data/ocr_service.dart';
import '../../features/commissions/data/commission_service.dart';

// Storage provider (must be overridden in main.dart)
final storageProvider = Provider<SecureStorage>((ref) {
  throw UnimplementedError('Storage provider must be initialized in main.dart');
});

// API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageProvider);
  return ApiClient(storage);
});

// Auth Service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(storageProvider);
  return AuthService(apiClient, storage);
});

// Subscription Service provider
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(storageProvider);
  return SubscriptionService(apiClient, storage);
});

// Interview Service provider
final interviewServiceProvider = Provider<InterviewService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InterviewService(apiClient);
});

// Document Service provider
final documentServiceProvider = Provider<DocumentService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DocumentService(apiClient);
});

// Offer Service provider
final offerServiceProvider = Provider<OfferService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OfferService(apiClient);
});

// File Service provider
final fileServiceProvider = Provider<FileService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FileService(apiClient);
});

// E-sign Service provider
final esignServiceProvider = Provider<EsignService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EsignService(apiClient);
});

// OCR Service provider
final ocrServiceProvider = Provider<OcrService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OcrService(apiClient);
});

// Commission Service provider
final commissionServiceProvider = Provider<CommissionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommissionService(apiClient);
});
