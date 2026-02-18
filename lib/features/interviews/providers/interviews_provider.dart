import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interview_model.dart';
import '../../../core/providers/providers.dart';

// State dla listy wywiadów
class InterviewsState {
  final List<InterviewModel> interviews;
  final bool isLoading;
  final String? error;

  InterviewsState({
    this.interviews = const [],
    this.isLoading = false,
    this.error,
  });

  InterviewsState copyWith({
    List<InterviewModel>? interviews,
    bool? isLoading,
    String? error,
  }) {
    return InterviewsState(
      interviews: interviews ?? this.interviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier dla listy wywiadów
class InterviewsNotifier extends StateNotifier<InterviewsState> {
  final Ref _ref;

  InterviewsNotifier(this._ref) : super(InterviewsState());

  Future<void> fetchInterviews() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final service = _ref.read(interviewServiceProvider);
      final interviews = await service.getInterviews();
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

  Future<void> deleteInterview(String id) async {
    final service = _ref.read(interviewServiceProvider);
    await service.deleteInterview(id);
    await fetchInterviews();
  }
}

// Provider dla listy wywiadów
final interviewsProvider = StateNotifierProvider<InterviewsNotifier, InterviewsState>((ref) {
  final notifier = InterviewsNotifier(ref);
  notifier.fetchInterviews();
  return notifier;
});
