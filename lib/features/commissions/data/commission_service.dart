import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/commission_model.dart';

class CommissionService {
  final ApiClient _apiClient;

  CommissionService(this._apiClient);

  Future<List<CommissionModel>> getCommissions() async {
    final response = await _apiClient.get(ApiEndpoints.commissions);
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => CommissionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
