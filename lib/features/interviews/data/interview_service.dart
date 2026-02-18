import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/interview_model.dart';
import '../../documents/models/document_model.dart';

class InterviewService {
  final ApiClient _apiClient;

  InterviewService(this._apiClient);

  /// Pobierz listę wywiadów
  Future<List<InterviewModel>> getInterviews() async {
    final response = await _apiClient.get(ApiEndpoints.interviews);
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => InterviewModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Pobierz szczegóły wywiadu
  Future<InterviewModel> getInterview(String id) async {
    final response = await _apiClient.get(ApiEndpoints.interviewById(id));
    return InterviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Pobierz szczegóły wywiadu (alias dla kompatybilności)
  Future<InterviewModel> getInterviewById(String id) async {
    return getInterview(id);
  }

  /// Utwórz nowy wywiad (draft)
  Future<InterviewModel> createInterview(CreateInterviewRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.interviews,
      data: request.toJson(),
    );
    return InterviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Zaktualizuj wywiad (tylko draft)
  Future<InterviewModel> updateInterview(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      ApiEndpoints.interviewById(id),
      data: data,
    );
    return InterviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Prześlij wywiad do zatwierdzenia
  Future<InterviewModel> submitInterview(String id) async {
    final response = await _apiClient.post('${ApiEndpoints.interviewById(id)}/submit');
    return InterviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Usuń wywiad (tylko draft)
  Future<void> deleteInterview(String id) async {
    await _apiClient.delete(ApiEndpoints.interviewById(id));
  }

  /// Generuj PDF dla wywiadu
  Future<DocumentModel> generatePdf(String id) async {
    final response = await _apiClient.post(ApiEndpoints.interviewPdf(id));
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Duplikuj wywiad (kopiuj jako nowy draft)
  Future<InterviewModel> duplicateInterview(String id) async {
    try {
      // Get original interview
      final original = await getInterview(id);
      
      // Create new interview with copied data
      final duplicateData = {
        'town': original.town,
        'visitDate': original.visitDate?.toIso8601String(),
        'ownerData': original.ownerData,
        'buildingAddress': original.buildingAddress,
        'buildingCore': original.buildingCore,
        'heating': original.heating,
        'notes': original.notes,
        'floors': original.floors.map((e) => e.toJson()).toList(),
      };
      
      final response = await _apiClient.post(
        ApiEndpoints.interviews,
        data: duplicateData,
      );
      
      return InterviewModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to duplicate interview: $e');
    }
  }

  /// Dodaj lub zaktualizuj kondygnację w wywiadzie
  Future<InterviewModel> saveFloor(String interviewId, Map<String, dynamic> floorData) async {
    try {
      // Pobierz aktualny wywiad
      final interview = await getInterview(interviewId);
      
      // Zaktualizuj listę kondygnacji
      final floors = List<Map<String, dynamic>>.from(
        interview.floors.map((f) => f.toJson()),
      );
      
      // Sprawdź czy to nowa kondygnacja (ID = timestamp) czy istniejąca (UUID)
      final floorId = floorData['id'] as String?;
      final isNewFloor = floorId == null || 
                         floorId.length < 20 || // Timestamp ID ma ~13 znaków
                         !floorId.contains('-'); // UUID zawiera myślniki
      
      // Pomocnicza funkcja do czyszczenia ID pomieszczeń
      Map<String, dynamic> _cleanFloorData(Map<String, dynamic> data, bool isNewFloor) {
        final cleanedData = Map<String, dynamic>.from(data);
        
        // Usuń ID kondygnacji jeśli nowa
        if (isNewFloor) {
          cleanedData.remove('id');
        }
        
        // Wyczyść pomieszczenia
        if (cleanedData['rooms'] is List) {
          final rooms = (cleanedData['rooms'] as List).map((room) {
            final roomMap = Map<String, dynamic>.from(room as Map<String, dynamic>);
            final roomId = roomMap['id'] as String?;
            
            // Jeśli ID pomieszczenia to timestamp (nowe pomieszczenie), usuń je
            if (roomId != null && (roomId.length < 20 || !roomId.contains('-'))) {
              roomMap.remove('id');
            }
            
            return roomMap;
          }).toList();
          
          cleanedData['rooms'] = rooms;
        }
        
        // Usuń puste/null wartości
        cleanedData.removeWhere((key, value) => value == null);
        
        return cleanedData;
      }
      
      if (isNewFloor) {
        // Nowa kondygnacja
        final newFloorData = _cleanFloorData(floorData, true);
        
        // Upewnij się że rooms to lista (może być pusta)
        if (!newFloorData.containsKey('rooms')) {
          newFloorData['rooms'] = [];
        }
        
        floors.add(newFloorData);
      } else {
        // Aktualizacja istniejącej kondygnacji
        final existingIndex = floors.indexWhere((f) => f['id'] == floorId);
        
        if (existingIndex >= 0) {
          final updatedFloorData = _cleanFloorData(floorData, false);
          floors[existingIndex] = updatedFloorData;
        } else {
          throw Exception('Floor with ID $floorId not found in interview');
        }
      }
      
      // Wyślij zaktualizowane dane do backendu
      final response = await _apiClient.patch(
        ApiEndpoints.interviewById(interviewId),
        data: {'floors': floors},
      );
      
      return InterviewModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to save floor: $e');
    }
  }

  /// Usuń kondygnację z wywiadu
  Future<InterviewModel> deleteFloor(String interviewId, String floorId) async {
    try {
      // Pobierz aktualny wywiad
      final interview = await getInterview(interviewId);
      
      // Usuń kondygnację z listy
      final floors = interview.floors
          .where((f) => f.id != floorId)
          .map((f) => f.toJson())
          .toList();
      
      // Wyślij zaktualizowane dane do backendu
      final response = await _apiClient.patch(
        ApiEndpoints.interviewById(interviewId),
        data: {'floors': floors},
      );
      
      return InterviewModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to delete floor: $e');
    }
  }
}
