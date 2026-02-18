import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../providers/interview_wizard_provider.dart';
import '../widgets/wizard_steps/owner_data_step.dart';
import '../widgets/wizard_steps/building_address_step.dart';
import '../widgets/wizard_steps/technical_data_step.dart';
import '../widgets/wizard_steps/photos_step.dart';
import '../widgets/wizard_steps/heating_step.dart';
import '../widgets/wizard_steps/woodwork_step.dart';
import '../widgets/wizard_steps/additional_notes_step.dart';
import '../widgets/wizard_steps/review_step.dart';
import '../widgets/wizard_steps/confirmation_step.dart';

class InterviewWizardScreen extends ConsumerStatefulWidget {
  const InterviewWizardScreen({super.key});

  @override
  ConsumerState<InterviewWizardScreen> createState() => _InterviewWizardScreenState();
}

class _InterviewWizardScreenState extends ConsumerState<InterviewWizardScreen> {
  Timer? _autoSaveTimer;
  DateTime? _lastAutoSave;

  @override
  void initState() {
    super.initState();
    _startAutoSave();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    final wizardState = ref.read(interviewWizardProvider);

    if (wizardState.isSaving || wizardState.currentStep >= wizardState.totalSteps - 1) {
      return;
    }

    try {
      await ref.read(interviewWizardProvider.notifier).saveDraft();
      _lastAutoSave = DateTime.now();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Auto-save: ${_formatTime(_lastAutoSave!)}'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Auto-save error: $e');
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  Widget _buildStepContent(WizardStep step) {
    switch (step) {
      case WizardStep.ownerData:
        return const OwnerDataStep();
      case WizardStep.buildingAddress:
        return const BuildingAddressStep();
      case WizardStep.technicalData:
        return const TechnicalDataStep();
      case WizardStep.photos:
        return const PhotosStep();
      case WizardStep.heating:
        return const HeatingStep();
      case WizardStep.woodwork:
        return const WoodworkStep();
      case WizardStep.additionalNotes:
        return const AdditionalNotesStep();
      case WizardStep.review:
        return const ReviewStep();
      case WizardStep.confirmation:
        return const ConfirmationStep();
    }
  }

  String _getStepTitle(WizardStep step) {
    switch (step) {
      case WizardStep.ownerData:
        return 'Dane właściciela';
      case WizardStep.buildingAddress:
        return 'Adres budynku';
      case WizardStep.technicalData:
        return 'Dane techniczne';
      case WizardStep.photos:
        return 'Zdjęcia';
      case WizardStep.heating:
        return 'Ogrzewanie i wentylacja';
      case WizardStep.woodwork:
        return 'Stolarka i elewacja';
      case WizardStep.additionalNotes:
        return 'Uwagi dodatkowe';
      case WizardStep.review:
        return 'Przegląd';
      case WizardStep.confirmation:
        return 'Potwierdzenie';
    }
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(interviewWizardProvider);
    final currentStep = wizardState.currentWizardStep;
    final hasConsent = wizardState.formData['consent'] as bool? ?? false;
    
    // Sprawdzamy czy jesteśmy na kroku "review" (przedostatnim)
    final isReviewStep = currentStep == WizardStep.review;
    final canProceedFromReview = !isReviewStep || hasConsent;

    return PopScope(
      canPop: wizardState.currentStep == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (wizardState.currentStep > 0) {
          await _performAutoSave();
          ref.read(interviewWizardProvider.notifier).previousStep();
          return;
        }

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Opuścić kreator?'),
            content: const Text('Niezapisane zmiany zostaną utracone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Anuluj'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Opuść'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getStepTitle(currentStep)),
          actions: [
            if (_lastAutoSave != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    'Zapisano: ${_formatTime(_lastAutoSave!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            if (wizardState.currentStep < wizardState.totalSteps - 1)
              TextButton.icon(
                onPressed: wizardState.isSaving
                    ? null
                    : () async {
                        try {
                          await ref.read(interviewWizardProvider.notifier).saveDraft();
                          _lastAutoSave = DateTime.now();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Szkic zapisany pomyślnie'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Błąd zapisywania: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                icon: wizardState.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Zapisz szkic'),
              ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: wizardState.progress,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Krok ${wizardState.currentStep + 1} z ${wizardState.totalSteps}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${(wizardState.progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildStepContent(currentStep),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (wizardState.currentStep > 0)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _performAutoSave();
                        ref.read(interviewWizardProvider.notifier).previousStep();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Wstecz'),
                    ),
                  const Spacer(),
                  if (wizardState.currentStep < wizardState.totalSteps - 1)
                    ElevatedButton.icon(
                      // Blokuj przycisk "Dalej" na kroku review jeśli nie ma zgody
                      onPressed: !canProceedFromReview
                          ? null
                          : () async {
                              // Jeśli jesteśmy na review i brak zgody, pokaż komunikat
                              if (isReviewStep && !hasConsent) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Musisz potwierdzić poprawność danych, aby kontynuować'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              
                              await _performAutoSave();
                              ref.read(interviewWizardProvider.notifier).nextStep();
                            },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Dalej'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: (!hasConsent || wizardState.isSaving)
                          ? null
                          : () async {
                              try {
                                await ref
                                    .read(interviewWizardProvider.notifier)
                                    .submitInterview();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Wywiad zapisany i wysłany pomyślnie!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  context.go('/interviews');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Błąd zapisywania wywiadu: $e'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              }
                            },
                      icon: wizardState.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Zakończ'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
