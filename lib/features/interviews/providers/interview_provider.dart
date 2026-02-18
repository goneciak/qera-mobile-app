import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../models/interview_model.dart';

class InterviewListState {
  final List<InterviewModel> interviews;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? statusFilter;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  InterviewListState({
    this.interviews = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.statusFilter,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  InterviewListState copyWith({
    List<InterviewModel>? interviews,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return InterviewListState(
      interviews: interviews ?? this.interviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

class InterviewListNotifier extends StateNotifier<InterviewListState> {
  final Ref _ref;

  InterviewListNotifier(this._ref) : super(InterviewListState()) {
    fetchInterviews();
  }

  Future<void> fetchInterviews() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final service = _ref.read(interviewServiceProvider);
      var interviews = await service.getInterviews();
      
      // Filtruj po stronie klienta
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        interviews = interviews.where((interview) {
          final query = state.searchQuery!.toLowerCase();
          
          // Search in town
          final townMatch = interview.town?.toLowerCase().contains(query) ?? false;
          
          // Search in owner data
          final ownerData = interview.ownerData ?? {};
          final firstName = ownerData['firstName']?.toString() ?? '';
          final lastName = ownerData['lastName']?.toString() ?? '';
          final ownerName = '$firstName $lastName'.toLowerCase();
          final ownerMatch = ownerName.contains(query);
          
          // Search in building address
          final address = interview.buildingAddress ?? {};
          final city = address['city']?.toString() ?? '';
          final addressMatch = city.toLowerCase().contains(query);
          
          return townMatch || ownerMatch || addressMatch;
        }).toList();
      }
      
      if (state.statusFilter != null) {
        interviews = interviews.where((interview) {
          return interview.status == state.statusFilter;
        }).toList();
      }
      
      state = state.copyWith(
        interviews: interviews,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchInterviews();
  }

  void setStatusFilter(String? status) {
    if (status == null) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
    fetchInterviews();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearStatusFilter: true,
    );
    fetchInterviews();
  }

  Future<void> deleteInterview(String id) async {
    final service = _ref.read(interviewServiceProvider);
    await service.deleteInterview(id);
    fetchInterviews();
  }

  Future<void> updateInterview(String id, Map<String, dynamic> data) async {
    try {
      final service = _ref.read(interviewServiceProvider);
      await service.updateInterview(id, data);
      fetchInterviews();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// Interview List Provider
final interviewListProvider =
    StateNotifierProvider<InterviewListNotifier, InterviewListState>((ref) {
  return InterviewListNotifier(ref);
});
