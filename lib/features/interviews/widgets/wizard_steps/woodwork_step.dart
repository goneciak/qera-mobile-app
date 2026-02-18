import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/interview_wizard_provider.dart';

class WoodworkStep extends ConsumerStatefulWidget {
  const WoodworkStep({super.key});

  @override
  ConsumerState<WoodworkStep> createState() => _WoodworkStepState();
}

class _WoodworkStepState extends ConsumerState<WoodworkStep> {
  String? _windowType;
  String? _doorType;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final wizardState = ref.read(interviewWizardProvider);
    final buildingCore = wizardState.formData['buildingCore'] as Map<String, dynamic>?;

    if (buildingCore != null) {
      _windowType = buildingCore['windowType'] as String?;
      _doorType = buildingCore['doorType'] as String?;
    }
  }

  void _saveData() {
    final current = ref.read(interviewWizardProvider).formData['buildingCore'] as Map<String, dynamic>? ?? {};
    ref.read(interviewWizardProvider.notifier).updateFormData({
      'buildingCore': {
        ...current,
        'windowType': _windowType,
        'doorType': _doorType,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stolarka okienna i drzwiowa',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),

        DropdownButtonFormField<String>(
          initialValue: _windowType,
          decoration: const InputDecoration(
            labelText: 'Typ okien',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.window),
          ),
          items: ['PVC', 'Drewniane', 'Aluminiowe', 'Drewniano-aluminiowe']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            setState(() => _windowType = value);
            _saveData();
          },
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          initialValue: _doorType,
          decoration: const InputDecoration(
            labelText: 'Typ drzwi zewnętrznych',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.door_front_door),
          ),
          items: ['Drewniane', 'PVC', 'Aluminiowe', 'Stalowe']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            setState(() => _doorType = value);
            _saveData();
          },
        ),
      ],
    );
  }
}
