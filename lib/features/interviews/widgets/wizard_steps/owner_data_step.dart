import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/interview_wizard_provider.dart';

class OwnerDataStep extends ConsumerStatefulWidget {
  const OwnerDataStep({super.key});

  @override
  ConsumerState<OwnerDataStep> createState() => _OwnerDataStepState();
}

class _OwnerDataStepState extends ConsumerState<OwnerDataStep> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _peselController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final wizardState = ref.read(interviewWizardProvider);
    final ownerData = wizardState.formData['ownerData'] as Map<String, dynamic>?;

    if (ownerData != null) {
      _firstNameController.text = ownerData['firstName'] as String? ?? '';
      _lastNameController.text = ownerData['lastName'] as String? ?? '';
      _emailController.text = ownerData['email'] as String? ?? '';
      _phoneController.text = ownerData['phone'] as String? ?? '';
      _peselController.text = ownerData['pesel'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _peselController.dispose();
    super.dispose();
  }

  void _saveData() {
    if (_formKey.currentState!.validate()) {
      ref.read(interviewWizardProvider.notifier).updateFormData({
        'ownerData': {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'pesel': _peselController.text,
        },
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dane właściciela',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Wprowadź dane kontaktowe właściciela budynku',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          // Imię
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Imię *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Wprowadź imię';
              }
              return null;
            },
            onChanged: (_) => _saveData(),
          ),
          const SizedBox(height: 16),

          // Nazwisko
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Nazwisko *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Wprowadź nazwisko';
              }
              return null;
            },
            onChanged: (_) => _saveData(),
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Wprowadź email';
              }
              if (!value.contains('@')) {
                return 'Wprowadź poprawny email';
              }
              return null;
            },
            onChanged: (_) => _saveData(),
          ),
          const SizedBox(height: 16),

          // Telefon
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
              hintText: '+48 123 456 789',
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Wprowadź telefon';
              }
              return null;
            },
            onChanged: (_) => _saveData(),
          ),
          const SizedBox(height: 16),

          // PESEL (opcjonalny)
          TextFormField(
            controller: _peselController,
            decoration: const InputDecoration(
              labelText: 'PESEL (opcjonalnie)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
            ),
            keyboardType: TextInputType.number,
            maxLength: 11,
            onChanged: (_) => _saveData(),
          ),
        ],
      ),
    );
  }
}
