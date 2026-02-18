import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/interview_wizard_provider.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(interviewWizardProvider);
    final formData = wizardState.formData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Przegląd danych',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Sprawdź wprowadzone dane przed wysłaniem',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 24),
        
        // Dane właściciela
        _buildSection(
          context,
          'Dane właściciela',
          Icons.person,
          _buildOwnerData(formData['ownerData'] as Map<String, dynamic>?),
        ),
        
        // Adres
        _buildSection(
          context,
          'Adres budynku',
          Icons.location_on,
          _buildAddressData(formData['buildingAddress'] as Map<String, dynamic>?),
        ),
        
        // Dane techniczne
        _buildSection(
          context,
          'Dane techniczne',
          Icons.home_work,
          _buildTechnicalData(formData['buildingCore'] as Map<String, dynamic>?),
        ),
        
        // Uwagi
        if (formData['notes'] != null && (formData['notes'] as String).isNotEmpty)
          _buildSection(
            context,
            'Uwagi',
            Icons.notes,
            [Text(formData['notes'] as String)],
          ),
        
        const SizedBox(height: 24),
        
        // Zgoda - wymagana
        Card(
          color: Colors.blue.shade50,
          child: CheckboxListTile(
            value: formData['consent'] as bool? ?? false,
            onChanged: (value) {
              ref.read(interviewWizardProvider.notifier).updateFormData({
                'consent': value ?? false,
              });
            },
            title: const Text(
              'Potwierdzam poprawność wprowadzonych danych *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Dane zostaną wysłane do firmy w celu wyceny. To pole jest wymagane.',
              style: TextStyle(fontSize: 12),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        
        if (formData['consent'] != true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zaznacz zgodę, aby móc zakończyć i wysłać wywiad',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOwnerData(Map<String, dynamic>? data) {
    if (data == null) return [const Text('Brak danych')];
    
    return [
      _buildDataRow('Imię i nazwisko', '${data['firstName']} ${data['lastName']}'),
      _buildDataRow('Email', data['email']),
      _buildDataRow('Telefon', data['phone']),
      if (data['pesel'] != null && (data['pesel'] as String).isNotEmpty)
        _buildDataRow('PESEL', data['pesel']),
    ];
  }

  List<Widget> _buildAddressData(Map<String, dynamic>? data) {
    if (data == null) return [const Text('Brak danych')];
    
    return [
      _buildDataRow('Ulica', '${data['street']} ${data['buildingNumber']}${data['apartmentNumber'] != null ? '/${data['apartmentNumber']}' : ''}'),
      _buildDataRow('Kod pocztowy', data['postalCode']),
      _buildDataRow('Miejscowość', data['city']),
      _buildDataRow('Województwo', data['voivodeship']),
    ];
  }

  List<Widget> _buildTechnicalData(Map<String, dynamic>? data) {
    if (data == null) return [const Text('Brak danych')];
    
    return [
      if (data['buildingType'] != null)
        _buildDataRow('Typ budynku', data['buildingType']),
      if (data['usableArea'] != null)
        _buildDataRow('Powierzchnia użytkowa', '${data['usableArea']} m²'),
      if (data['numberOfFloors'] != null)
        _buildDataRow('Liczba kondygnacji', data['numberOfFloors'].toString()),
      if (data['yearBuilt'] != null)
        _buildDataRow('Rok budowy', data['yearBuilt'].toString()),
      if (data['wallMaterial'] != null)
        _buildDataRow('Materiał ścian', data['wallMaterial']),
    ];
  }

  Widget _buildDataRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
