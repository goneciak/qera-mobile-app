import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/interview_wizard_provider.dart';

class HeatingStep extends ConsumerStatefulWidget {
  const HeatingStep({super.key});

  @override
  ConsumerState<HeatingStep> createState() => _HeatingStepState();
}

class _HeatingStepState extends ConsumerState<HeatingStep> {
  String? _heatingType;
  String? _heatingSource;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final wizardState = ref.read(interviewWizardProvider);
    final heating = wizardState.formData['heating'] as Map<String, dynamic>?;

    if (heating != null) {
      _heatingType = heating['type'] as String?;
      _heatingSource = heating['source'] as String?;
    }
  }

  void _saveData() {
    ref.read(interviewWizardProvider.notifier).updateFormData({
      'heating': {
        'type': _heatingType,
        'source': _heatingSource,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ogrzewanie i wentylacja',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        
        DropdownButtonFormField<String>(
          initialValue: _heatingType,
          decoration: const InputDecoration(
            labelText: 'Typ ogrzewania',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.thermostat),
          ),
          items: ['Centralne', 'Piece kaflowe', 'Kominek', 'Pompa ciepła', 'Elektryczne']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            setState(() => _heatingType = value);
            _saveData();
          },
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          initialValue: _heatingSource,
          decoration: const InputDecoration(
            labelText: 'Źródło ciepła',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.local_fire_department),
          ),
          items: ['Gaz', 'Węgiel', 'Drewno', 'Olej', 'Prąd', 'Pompa ciepła']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            setState(() => _heatingSource = value);
            _saveData();
          },
        ),
      ],
    );
  }
}
