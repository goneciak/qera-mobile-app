import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interview_model.dart';
import '../data/interview_service.dart';
import '../../../core/providers/providers.dart';
import 'interviews_provider.dart';

// Wizard step enum
enum WizardStep {
  ownerData,
  buildingAddress,
  technicalData,
  photos,
  heating,
  woodwork,
  additionalNotes,
  review,
  confirmation,
}

class InterviewWizardState {
  final int currentStep;
  final Map<String, dynamic> formData;
  final bool isSaving;
  final String? error;
  final String? draftId;

  InterviewWizardState({
    this.currentStep = 0,
    this.formData = const {},
    this.isSaving = false,
    this.error,
    this.draftId,
  });

  // Alias getter dla backward compatibility
  String? get interviewId => draftId;

  InterviewWizardState copyWith({
    int? currentStep,
    Map<String, dynamic>? formData,
    bool? isSaving,
    String? error,
    String? draftId,
  }) {
    return InterviewWizardState(
      currentStep: currentStep ?? this.currentStep,
      formData: formData ?? this.formData,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      draftId: draftId ?? this.draftId,
    );
  }

  WizardStep get currentWizardStep {
    if (currentStep >= 0 && currentStep < WizardStep.values.length) {
      return WizardStep.values[currentStep];
    }
    return WizardStep.ownerData;
  }

  int get totalSteps => WizardStep.values.length;

  double get progress => (currentStep + 1) / totalSteps;
}

class InterviewWizardNotifier extends StateNotifier<InterviewWizardState> {
  final InterviewService _service;
  final Ref _ref;

  InterviewWizardNotifier(this._service, this._ref) : super(InterviewWizardState());

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      _autoSave();
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  void updateFormData(Map<String, dynamic> data) {
    final updatedData = Map<String, dynamic>.from(state.formData)..addAll(data);
    state = state.copyWith(formData: updatedData);
  }

  Future<void> _autoSave() async {
    // Auto-save after each step
    if (state.draftId != null) {
      await saveDraft();
    }
  }

  Future<void> saveDraft() async {
    state = state.copyWith(isSaving: true, error: null);
    
    try {
      final request = _buildCreateRequest();
      
      // Debug logging
      debugPrint('🔵 Saving draft...');
      debugPrint('🔵 Current draftId: ${state.draftId}');
      debugPrint('🔵 Form data: ${state.formData}');
      debugPrint('🔵 Request JSON: ${request.toJson()}');
      
      if (state.draftId == null) {
        // Create new draft
        debugPrint('🔵 Creating new draft...');
        final interview = await _service.createInterview(request);
        debugPrint('🟢 Draft created successfully! ID: ${interview.id}');
        state = state.copyWith(
          isSaving: false,
          draftId: interview.id,
        );
      } else {
        // Update existing draft
        debugPrint('🔵 Updating existing draft: ${state.draftId}');
        await _service.updateInterview(state.draftId!, request.toJson());
        debugPrint('🟢 Draft updated successfully!');
        state = state.copyWith(isSaving: false);
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 Error saving draft: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> submitInterview() async {
    state = state.copyWith(isSaving: true, error: null);
    
    try {
      final request = _buildCreateRequest();
      
      debugPrint('🔵 Submitting interview...');
      debugPrint('🔵 Current draftId: ${state.draftId}');
      debugPrint('🔵 Request JSON: ${request.toJson()}');
      
      String interviewId;
      
      if (state.draftId == null) {
        // Create new interview
        debugPrint('🔵 Creating new interview...');
        final interview = await _service.createInterview(request);
        interviewId = interview.id;
        debugPrint('🟢 Interview created! ID: $interviewId');
      } else {
        // Update existing draft
        debugPrint('🔵 Updating existing draft before submit: ${state.draftId}');
        await _service.updateInterview(state.draftId!, request.toJson());
        interviewId = state.draftId!;
        debugPrint('🟢 Interview updated! ID: $interviewId');
      }
      
      // Submit for approval
      debugPrint('🔵 Submitting interview for approval: $interviewId');
      await _service.submitInterview(interviewId);
      debugPrint('🟢 Interview submitted successfully!');
      
      // Refresh interviews list
      debugPrint('🔵 Refreshing interviews list...');
      _ref.read(interviewsProvider.notifier).fetchInterviews();
      
      state = state.copyWith(isSaving: false);
      debugPrint('🟢 Submit complete!');
    } catch (e, stackTrace) {
      debugPrint('🔴 Error submitting interview: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  CreateInterviewRequest _buildCreateRequest() {
    return CreateInterviewRequest(
      town: state.formData['town'] as String?,
      visitDate: state.formData['visitDate'] as DateTime?,
      ownerData: state.formData['ownerData'] as Map<String, dynamic>?,
      buildingAddress: state.formData['buildingAddress'] as Map<String, dynamic>?,
      buildingCore: state.formData['buildingCore'] as Map<String, dynamic>?,
      heating: state.formData['heating'] as Map<String, dynamic>?,
      notes: state.formData['notes'] as String?,
      consent: state.formData['consent'] as bool? ?? false,
      floors: (state.formData['floors'] as List<dynamic>?)
              ?.map((e) => FloorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  void reset() {
    state = InterviewWizardState();
  }
}

final interviewWizardProvider =
    StateNotifierProvider<InterviewWizardNotifier, InterviewWizardState>((ref) {
  final service = ref.watch(interviewServiceProvider);
  return InterviewWizardNotifier(service, ref);
});
