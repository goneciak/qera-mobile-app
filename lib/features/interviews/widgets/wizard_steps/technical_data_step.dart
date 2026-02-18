import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/interview_wizard_provider.dart';

class TechnicalDataStep extends ConsumerStatefulWidget {
  const TechnicalDataStep({super.key});

  @override
  ConsumerState<TechnicalDataStep> createState() => _TechnicalDataStepState();
}

class _TechnicalDataStepState extends ConsumerState<TechnicalDataStep> {
  final _formKey = GlobalKey<FormState>();
  final _usableAreaController = TextEditingController();
  final _heatedAreaController = TextEditingController();
  final _buildingHeightController = TextEditingController();
  final _numberOfFloorsController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  String? _buildingType;
  String? _wallMaterial;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final wizardState = ref.read(interviewWizardProvider);
    final techData = wizardState.formData['buildingCore'] as Map<String, dynamic>?;
    
    if (techData != null) {
      _usableAreaController.text = techData['usableArea']?.toString() ?? '';
      _heatedAreaController.text = techData['heatedArea']?.toString() ?? '';
      _buildingHeightController.text = techData['buildingHeight']?.toString() ?? '';
      _numberOfFloorsController.text = techData['numberOfFloors']?.toString() ?? '';
      _yearBuiltController.text = techData['yearBuilt']?.toString() ?? '';
      _buildingType = techData['buildingType'] as String?;
      _wallMaterial = techData['wallMaterial'] as String?;
    }
  }

  @override
  void dispose() {
    _usableAreaController.dispose();
    _heatedAreaController.dispose();
    _buildingHeightController.dispose();
    _numberOfFloorsController.dispose();
    _yearBuiltController.dispose();
    super.dispose();
  }

  void _saveData() {
    if (_formKey.currentState!.validate()) {
      ref.read(interviewWizardProvider.notifier).updateFormData({
        'buildingCore': {
          'usableArea': double.tryParse(_usableAreaController.text),
          'heatedArea': double.tryParse(_heatedAreaController.text),
          'buildingHeight': double.tryParse(_buildingHeightController.text),
          'numberOfFloors': int.tryParse(_numberOfFloorsController.text),
          'yearBuilt': int.tryParse(_yearBuiltController.text),
          'buildingType': _buildingType,
          'wallMaterial': _wallMaterial,
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
            'Dane techniczne budynku',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Podstawowe informacje o budynku',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          
          // Typ budynku
          DropdownButtonFormField<String>(
            initialValue: _buildingType,
            decoration: const InputDecoration(
              labelText: 'Typ budynku *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home_work),
            ),
            items: [
              'Dom jednorodzinny',
              'Budynek wielorodzinny',
              'Kamienica',
              'Bliźniak',
              'Szeregowiec',
              'Gospodarstwo rolne',
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _buildingType = value);
              _saveData();
            },
            validator: (value) {
              if (value == null) return 'Wybierz typ budynku';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Powierzchnia użytkowa i ogrzewana
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _usableAreaController,
                  decoration: const InputDecoration(
                    labelText: 'Pow. użytkowa (m²) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.square_foot),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wymagane';
                    if (double.tryParse(value) == null) return 'Nieprawidłowa wartość';
                    return null;
                  },
                  onChanged: (_) => _saveData(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _heatedAreaController,
                  decoration: const InputDecoration(
                    labelText: 'Pow. ogrzewana (m²)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _saveData(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Wysokość i liczba kondygnacji
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _buildingHeightController,
                  decoration: const InputDecoration(
                    labelText: 'Wysokość (m)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _saveData(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _numberOfFloorsController,
                  decoration: const InputDecoration(
                    labelText: 'Liczba kondygnacji *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wymagane';
                    if (int.tryParse(value) == null) return 'Nieprawidłowa wartość';
                    return null;
                  },
                  onChanged: (_) => _saveData(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Rok budowy
          TextFormField(
            controller: _yearBuiltController,
            decoration: const InputDecoration(
              labelText: 'Rok budowy *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
              hintText: 'np. 2020',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Wymagane';
              final year = int.tryParse(value);
              if (year == null || year < 1800 || year > DateTime.now().year) {
                return 'Nieprawidłowy rok';
              }
              return null;
            },
            onChanged: (_) => _saveData(),
          ),
          const SizedBox(height: 16),
          
          // Materiał ścian
          DropdownButtonFormField<String>(
            initialValue: _wallMaterial,
            decoration: const InputDecoration(
              labelText: 'Materiał ścian *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.construction),
            ),
            items: [
              'Cegła',
              'Pustak ceramiczny',
              'Pustak betonowy',
              'Beton komórkowy',
              'Keramzyt',
              'Drewno',
              'Inne',
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _wallMaterial = value);
              _saveData();
            },
            validator: (value) {
              if (value == null) return 'Wybierz materiał';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
