import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/interview_wizard_provider.dart';

class AdditionalNotesStep extends ConsumerStatefulWidget {
  const AdditionalNotesStep({super.key});

  @override
  ConsumerState<AdditionalNotesStep> createState() => _AdditionalNotesStepState();
}

class _AdditionalNotesStepState extends ConsumerState<AdditionalNotesStep> {
  final _notesController = TextEditingController();
  DateTime? _visitDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final wizardState = ref.read(interviewWizardProvider);
    _notesController.text = wizardState.formData['notes'] as String? ?? '';
    _visitDate = wizardState.formData['visitDate'] as DateTime?;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(interviewWizardProvider.notifier).updateFormData({
      'notes': _notesController.text,
      'visitDate': _visitDate,
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _visitDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _visitDate = date);
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uwagi dodatkowe',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        
        ListTile(
          title: const Text('Data wizyty'),
          subtitle: Text(_visitDate != null 
              ? '${_visitDate!.day}.${_visitDate!.month}.${_visitDate!.year}'
              : 'Nie wybrano'),
          leading: const Icon(Icons.calendar_today),
          trailing: const Icon(Icons.edit),
          onTap: _selectDate,
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Dodatkowe uwagi',
            border: OutlineInputBorder(),
            hintText: 'Wprowadź dodatkowe informacje o budynku...',
          ),
          maxLines: 10,
          onChanged: (_) => _saveData(),
        ),
      ],
    );
  }
}
