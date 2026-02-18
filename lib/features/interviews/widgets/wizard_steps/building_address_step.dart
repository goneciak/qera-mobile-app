import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/interview_wizard_provider.dart';

class BuildingAddressStep extends ConsumerStatefulWidget {
  const BuildingAddressStep({super.key});

  @override
  ConsumerState<BuildingAddressStep> createState() => _BuildingAddressStepState();
}

class _BuildingAddressStepState extends ConsumerState<BuildingAddressStep> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _buildingNumberController = TextEditingController();
  final _apartmentNumberController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _voivodeshipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final wizardState = ref.read(interviewWizardProvider);
    final addressData = wizardState.formData['buildingAddress'] as Map<String, dynamic>?;
    
    if (addressData != null) {
      _streetController.text = addressData['street'] as String? ?? '';
      _buildingNumberController.text = addressData['buildingNumber'] as String? ?? '';
      _apartmentNumberController.text = addressData['apartmentNumber'] as String? ?? '';
      _postalCodeController.text = addressData['postalCode'] as String? ?? '';
      _cityController.text = addressData['city'] as String? ?? '';
      _voivodeshipController.text = addressData['voivodeship'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _buildingNumberController.dispose();
    _apartmentNumberController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _voivodeshipController.dispose();
    super.dispose();
  }

  void _saveData() {
    if (_formKey.currentState!.validate()) {
      ref.read(interviewWizardProvider.notifier).updateFormData({
        'buildingAddress': {
          'street': _streetController.text,
          'buildingNumber': _buildingNumberController.text,
          'apartmentNumber': _apartmentNumberController.text,
          'postalCode': _postalCodeController.text,
          'city': _cityController.text,
          'voivodeship': _voivodeshipController.text,
        },
        'town': _cityController.text, // Backend wymaga osobnego pola town
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
            'Adres budynku',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Wprowadź dokładny adres budynku objętego wywiadem',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          
          // Ulica
          TextFormField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Ulica *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Wprowadź nazwę ulicy';
              }
              return null;
            },
            onChanged: (_) => _saveData(),
          ),
          const SizedBox(height: 16),
          
          // Numer budynku i mieszkania
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _buildingNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nr budynku *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Wymagane';
                    }
                    return null;
                  },
                  onChanged: (_) => _saveData(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _apartmentNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nr lok.',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _saveData(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Kod pocztowy i miasto
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Kod pocztowy *',
                    border: OutlineInputBorder(),
                    hintText: '00-000',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Wymagane';
                    }
                    return null;
                  },
                  onChanged: (_) => _saveData(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Miejscowość *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Wprowadź miejscowość';
                    }
                    return null;
                  },
                  onChanged: (_) => _saveData(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Województwo
          DropdownButtonFormField<String>(
            initialValue: _voivodeshipController.text.isEmpty ? null : _voivodeshipController.text,
            decoration: const InputDecoration(
              labelText: 'Województwo *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.map),
            ),
            items: [
              'dolnośląskie',
              'kujawsko-pomorskie',
              'lubelskie',
              'lubuskie',
              'łódzkie',
              'małopolskie',
              'mazowieckie',
              'opolskie',
              'podkarpackie',
              'podlaskie',
              'pomorskie',
              'śląskie',
              'świętokrzyskie',
              'warmińsko-mazurskie',
              'wielkopolskie',
              'zachodniopomorskie',
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _voivodeshipController.text = value;
                _saveData();
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Wybierz województwo';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
