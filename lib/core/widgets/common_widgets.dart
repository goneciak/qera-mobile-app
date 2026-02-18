import 'package:flutter/material.dart';

/// Widget wyświetlający status badge dla wywiadów zgodnie ze specyfikacją
class InterviewStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const InterviewStatusBadge({
    Key? key,
    required this.status,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: compact 
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'DRAFT':
        return _StatusConfig('Szkic', Colors.grey);
      case 'SUBMITTED':
        return _StatusConfig('Wysłany do firmy', Colors.blue);
      case 'APPROVED':
        return _StatusConfig('Zatwierdzony', Colors.green);
      case 'REJECTED':
        return _StatusConfig('Odrzucony', Colors.red);
      case 'PDF_SENT':
        return _StatusConfig('Wysłano PDF', Colors.teal);
      case 'SIGNED_AUTENTI':
        return _StatusConfig('Podpisano (e-podpis)', Colors.green.shade700);
      case 'SIGNED_MANUAL_UPLOAD':
        return _StatusConfig('Podpisano (skan)', Colors.green.shade700);
      default:
        return _StatusConfig(status, Colors.grey);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  _StatusConfig(this.label, this.color);
}

/// Widget wyświetlający status badge dla ofert
class OfferStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const OfferStatusBadge({
    Key? key,
    required this.status,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: compact 
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'DRAFT':
        return _StatusConfig('Szkic', Colors.grey);
      case 'SENT':
        return _StatusConfig('Wysłana', Colors.blue);
      case 'CLIENT_ACCEPTED':
        return _StatusConfig('Zaakceptowana', Colors.orange);
      case 'APPROVED':
        return _StatusConfig('Zatwierdzona', Colors.green);
      case 'REJECTED':
        return _StatusConfig('Odrzucona', Colors.red);
      default:
        return _StatusConfig(status, Colors.grey);
    }
  }
}

/// Widget pokazujący banner "Brak internetu"
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade700,
      child: Row(
        children: const [
          Icon(Icons.cloud_off, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'Brak internetu - pracujesz w trybie offline',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Widget pokazujący postęp w wizardzie (stepper)
class WizardProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const WizardProgressIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (currentStep + 1) / totalSteps,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 8),
        // Step label
        Text(
          'Krok ${currentStep + 1} z $totalSteps: ${stepLabels[currentStep]}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Reużywalny widget do nawigacji w wizardzie
class WizardNavigationButtons extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSaveDraft;
  final bool isFirstStep;
  final bool isLastStep;
  final bool isLoading;
  final String? nextLabel;

  const WizardNavigationButtons({
    Key? key,
    this.onPrevious,
    this.onNext,
    this.onSaveDraft,
    this.isFirstStep = false,
    this.isLastStep = false,
    this.isLoading = false,
    this.nextLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Save draft button
          if (onSaveDraft != null)
            TextButton.icon(
              onPressed: isLoading ? null : onSaveDraft,
              icon: const Icon(Icons.save),
              label: const Text('Zapisz szkic'),
            ),
          const SizedBox(height: 8),
          // Navigation row
          Row(
            children: [
              // Previous button
              if (!isFirstStep)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onPrevious,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Wstecz'),
                  ),
                ),
              if (!isFirstStep) const SizedBox(width: 12),
              // Next button
              Expanded(
                flex: isFirstStep ? 1 : 1,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onNext,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(isLastStep ? Icons.check : Icons.arrow_forward),
                  label: Text(nextLabel ?? (isLastStep ? 'Zakończ' : 'Dalej')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wyświetla listę błędów walidacji
class ValidationErrorsList extends StatelessWidget {
  final Map<String, String> errors;
  final Function(String)? onErrorTap;

  const ValidationErrorsList({
    Key? key,
    required this.errors,
    this.onErrorTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Błędy walidacji:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...errors.entries.map((entry) {
              return InkWell(
                onTap: onErrorTap != null ? () => onErrorTap!(entry.key) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      if (onErrorTap != null)
                        const Icon(Icons.chevron_right, size: 16, color: Colors.red),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
