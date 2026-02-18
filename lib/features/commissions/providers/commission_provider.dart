import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../data/commission_service.dart';
import '../models/commission_model.dart';

// Service provider
final commissionServiceProvider = Provider<CommissionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommissionService(apiClient);
});

// Commissions list provider
final commissionsProvider = FutureProvider<List<CommissionModel>>((ref) async {
  final commissionService = ref.watch(commissionServiceProvider);
  return commissionService.getCommissions();
});

// Total commissions provider
final totalCommissionsProvider = Provider<double>((ref) {
  final commissionsAsync = ref.watch(commissionsProvider);
  return commissionsAsync.when(
    data: (commissions) {
      return commissions.fold(0.0, (sum, commission) => sum + commission.total);
    },
    loading: () => 0.0,
    error: (error, stack) => 0.0,
  );
});
