import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/interview_model.dart';
import '../models/floor_room_models.dart' as floor_models;
import '../data/interview_service.dart';
import '../../../core/providers/providers.dart';
import '../../../core/helpers/auto_save_helper.dart';
import '../../../core/constants/api_endpoints.dart';
import 'package:image_picker/image_picker.dart';
import 'floor_editor_screen.dart';

// Provider for single interview (full model)
final interviewDetailProvider = FutureProvider.family<InterviewModel, String>((ref, id) async {
  final service = ref.watch(interviewServiceProvider);
  return service.getInterviewById(id);
});

// State provider for edit mode
final editModeProvider = StateProvider.autoDispose<bool>((ref) => false);

// State provider for form data (auto-save)
final interviewFormDataProvider = StateProvider.autoDispose<Map<String, dynamic>>((ref) => {});

class InterviewDetailScreen extends ConsumerStatefulWidget {
  final String interviewId;

  const InterviewDetailScreen({
    super.key,
    required this.interviewId,
  });

  @override
  ConsumerState<InterviewDetailScreen> createState() => _InterviewDetailScreenState();
}

class _InterviewDetailScreenState extends ConsumerState<InterviewDetailScreen> {
  late AutoSaveHelper _autoSaveHelper;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _hasConsent = false; // Zgoda RODO

  // Controllers for form fields
  final _townController = TextEditingController();
  final _visitDateController = TextEditingController();
  
  // Owner data controllers
  final _ownerFirstNameController = TextEditingController();
  final _ownerLastNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerPeselController = TextEditingController();
  
  // Building address controllers
  final _streetController = TextEditingController();
  final _buildingNumberController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _voivodeshipController = TextEditingController();
  
  // Building core controllers
  final _buildingTypeController = TextEditingController();
  final _usableAreaController = TextEditingController();
  final _numberOfFloorsController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _wallMaterialController = TextEditingController();
  
  // Heating controllers
  final _heatingTypeController = TextEditingController();
  final _heatingSourceController = TextEditingController();
  
  // Notes
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _autoSaveHelper = AutoSaveHelper(
      onSave: _handleAutoSave,
      debounceMs: 2000,
    );
  }

  @override
  void dispose() {
    _autoSaveHelper.dispose();
    _townController.dispose();
    _visitDateController.dispose();
    _ownerFirstNameController.dispose();
    _ownerLastNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _ownerPeselController.dispose();
    _streetController.dispose();
    _buildingNumberController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _voivodeshipController.dispose();
    _buildingTypeController.dispose();
    _usableAreaController.dispose();
    _numberOfFloorsController.dispose();
    _yearBuiltController.dispose();
    _wallMaterialController.dispose();
    _heatingTypeController.dispose();
    _heatingSourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeControllers(InterviewModel interview) {
    _townController.text = interview.town ?? '';
    _visitDateController.text = interview.visitDate != null
        ? DateFormat('dd.MM.yyyy').format(interview.visitDate!)
        : '';
    
    // Owner data
    final ownerData = interview.ownerData ?? {};
    _ownerFirstNameController.text = ownerData['firstName']?.toString() ?? '';
    _ownerLastNameController.text = ownerData['lastName']?.toString() ?? '';
    _ownerEmailController.text = ownerData['email']?.toString() ?? '';
    _ownerPhoneController.text = ownerData['phone']?.toString() ?? '';
    _ownerPeselController.text = ownerData['pesel']?.toString() ?? '';
    
    // Building address
    final address = interview.buildingAddress ?? {};
    _streetController.text = address['street']?.toString() ?? '';
    _buildingNumberController.text = address['buildingNumber']?.toString() ?? '';
    _postalCodeController.text = address['postalCode']?.toString() ?? '';
    _cityController.text = address['city']?.toString() ?? '';
    _voivodeshipController.text = address['voivodeship']?.toString() ?? '';
    
    // Building core
    final building = interview.buildingCore ?? {};
    _buildingTypeController.text = building['buildingType']?.toString() ?? '';
    _usableAreaController.text = building['usableArea']?.toString() ?? '';
    _numberOfFloorsController.text = building['numberOfFloors']?.toString() ?? '';
    _yearBuiltController.text = building['yearBuilt']?.toString() ?? '';
    _wallMaterialController.text = building['wallMaterial']?.toString() ?? '';
    
    // Heating
    final heating = interview.heating ?? {};
    _heatingTypeController.text = heating['type']?.toString() ?? '';
    _heatingSourceController.text = heating['source']?.toString() ?? '';
    
    _notesController.text = interview.notes ?? '';
    
    // Inicjalizuj zgodę RODO
    _hasConsent = interview.consent;
  }

  Future<void> _handleAutoSave() async {
    if (!mounted) return;
    
    setState(() => _isSaving = true);
    
    try {
      final service = ref.read(interviewServiceProvider);
      final updateData = _buildUpdateData();
      
      // Debug: Wypisz dane przed wysłaniem
      print('🔵 AUTO-SAVE - Wysyłam dane:');
      print('📊 visitDate: ${updateData['visitDate']}');
      print('📊 town: ${updateData['town']}');
      print('📊 Full data: $updateData');
      
      await service.updateInterview(widget.interviewId, updateData);
      
      if (mounted) {
        ref.invalidate(interviewDetailProvider(widget.interviewId));
      }
    } catch (e) {
      print('❌ BŁĄD AUTO-SAVE:');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      
      if (mounted) {
        // Wyciągnij szczegóły błędu walidacji
        String errorMessage = 'Błąd auto-save: $e';
        
        if (e.toString().contains('validation')) {
          errorMessage = 'Błąd walidacji:\n${e.toString()}';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Nieprawidłowe dane (400):\n${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onFieldChanged() {
    _autoSaveHelper.trigger();
  }

  @override
  Widget build(BuildContext context) {
    final interviewAsync = ref.watch(interviewDetailProvider(widget.interviewId));
    final isEditMode = ref.watch(editModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły wywiadu'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          IconButton(
            icon: Icon(isEditMode ? Icons.visibility : Icons.edit),
            onPressed: () {
              ref.read(editModeProvider.notifier).state = !isEditMode;
            },
            tooltip: isEditMode ? 'Widok' : 'Edycja',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'scan_kw':
                  _scanDocument(context, 'KW');
                  break;
                case 'scan_id':
                  _scanDocument(context, 'ID');
                  break;
                case 'pdf':
                  interviewAsync.whenData((interview) => _generatePdf(context, ref, interview.id));
                  break;
                case 'submit':
                  interviewAsync.whenData((interview) => _submitInterview(context, ref, interview.id));
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'scan_kw',
                child: ListTile(
                  leading: Icon(Icons.document_scanner),
                  title: Text('Skanuj KW'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'scan_id',
                child: ListTile(
                  leading: Icon(Icons.badge),
                  title: Text('Skanuj dowód'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Generuj PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'submit',
                child: ListTile(
                  leading: Icon(Icons.send),
                  title: Text('Wyślij do firmy'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: interviewAsync.when(
        data: (interview) {
          // Initialize controllers once
          if (_townController.text.isEmpty) {
            _initializeControllers(interview);
          }
          
          return _buildContent(context, ref, interview, isEditMode);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Błąd: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(interviewDetailProvider(widget.interviewId)),
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isEditMode && interviewAsync.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => _saveManually(context, ref),
              icon: const Icon(Icons.save),
              label: const Text('Zapisz'),
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, InterviewModel interview, bool isEditMode) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status header
            _buildStatusHeader(context, interview),
            
            // Basic info section
            _buildBasicInfoSection(context, interview, isEditMode),
            
            // Owner data section
            _buildOwnerDataSection(context, interview, isEditMode),
            
            // Building address section
            _buildAddressSection(context, interview, isEditMode),
            
            // Building core section
            _buildBuildingCoreSection(context, interview, isEditMode),
            
            // Heating section
            _buildHeatingSection(context, interview, isEditMode),
            
            // Floors section (preview only for now)
            _buildFloorsSection(context, interview),
            
            // Notes section
            _buildNotesSection(context, interview, isEditMode),
            
            // Actions section
            if (!isEditMode) _buildActionsSection(context, ref, interview),
            
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, InterviewModel interview) {
    final status = InterviewStatus.fromString(interview.status);
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: _getStatusColor(interview.status).withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                status.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _getStatusColor(interview.status),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          if (interview.status == 'DRAFT')
            ElevatedButton.icon(
              onPressed: () => _submitInterview(context, ref, interview.id),
              icon: const Icon(Icons.send),
              label: const Text('Wyślij'),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, InterviewModel interview, bool isEditMode) {
    return _buildSection(
      context,
      'Informacje podstawowe',
      Icons.info,
      [
        if (isEditMode) ...[
          TextFormField(
            controller: _townController,
            decoration: const InputDecoration(
              labelText: 'Miejscowość',
              hintText: 'np. Warszawa',
            ),
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _visitDateController,
            decoration: const InputDecoration(
              labelText: 'Data wizyty',
              hintText: 'dd.mm.rrrr',
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () => _selectDate(context),
            readOnly: true,
          ),
        ] else ...[
          if (interview.town != null)
            _buildDataRow('Miejscowość', interview.town!),
          if (interview.visitDate != null)
            _buildDataRow('Data wizyty', DateFormat('dd.MM.yyyy').format(interview.visitDate!)),
          _buildDataRow('Data utworzenia', DateFormat('dd.MM.yyyy HH:mm').format(interview.createdAt)),
        ],
      ],
    );
  }

  Widget _buildOwnerDataSection(BuildContext context, InterviewModel interview, bool isEditMode) {
    final ownerData = interview.ownerData ?? {};
    
    return _buildSection(
      context,
      'Dane właściciela',
      Icons.person,
      [
        if (isEditMode) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ownerFirstNameController,
                  decoration: const InputDecoration(labelText: 'Imię'),
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _ownerLastNameController,
                  decoration: const InputDecoration(labelText: 'Nazwisko'),
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ownerEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'jan.kowalski@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ownerPhoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon',
              hintText: '+48 123 456 789',
            ),
            keyboardType: TextInputType.phone,
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ownerPeselController,
            decoration: const InputDecoration(
              labelText: 'PESEL',
              hintText: '12345678901',
            ),
            keyboardType: TextInputType.number,
            maxLength: 11,
            onChanged: (_) => _onFieldChanged(),
          ),
        ] else ...[
          if (ownerData['firstName'] != null || ownerData['lastName'] != null)
            _buildDataRow('Imię i nazwisko', '${ownerData['firstName'] ?? ''} ${ownerData['lastName'] ?? ''}'.trim()),
          if (ownerData['email'] != null)
            _buildDataRow('Email', ownerData['email'].toString()),
          if (ownerData['phone'] != null)
            _buildDataRow('Telefon', ownerData['phone'].toString()),
          if (ownerData['pesel'] != null)
            _buildDataRow('PESEL', ownerData['pesel'].toString()),
        ],
      ],
    );
  }

  Widget _buildAddressSection(BuildContext context, InterviewModel interview, bool isEditMode) {
    final address = interview.buildingAddress ?? {};
    
    return _buildSection(
      context,
      'Adres budynku',
      Icons.location_on,
      [
        if (isEditMode) ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _streetController,
                  decoration: const InputDecoration(labelText: 'Ulica'),
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _buildingNumberController,
                  decoration: const InputDecoration(labelText: 'Nr'),
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(labelText: 'Kod pocztowy'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'Miasto'),
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _voivodeshipController,
            decoration: const InputDecoration(labelText: 'Województwo'),
            onChanged: (_) => _onFieldChanged(),
          ),
        ] else ...[
          if (address['street'] != null)
            _buildDataRow('Ulica', '${address['street']} ${address['buildingNumber'] ?? ''}'),
          if (address['postalCode'] != null && address['city'] != null)
            _buildDataRow('Kod i miasto', '${address['postalCode']} ${address['city']}'),
          if (address['voivodeship'] != null)
            _buildDataRow('Województwo', address['voivodeship'].toString()),
        ],
      ],
    );
  }

  Widget _buildBuildingCoreSection(BuildContext context, InterviewModel interview, bool isEditMode) {
    final building = interview.buildingCore ?? {};
    
    return _buildSection(
      context,
      'Dane techniczne budynku',
      Icons.construction,
      [
        if (isEditMode) ...[
          TextFormField(
            controller: _buildingTypeController,
            decoration: const InputDecoration(
              labelText: 'Typ budynku',
              hintText: 'Dom jednorodzinny, Mieszkanie, itp.',
            ),
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _usableAreaController,
                  decoration: const InputDecoration(
                    labelText: 'Powierzchnia użytkowa',
                    suffixText: 'm²',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _numberOfFloorsController,
                  decoration: const InputDecoration(labelText: 'Liczba kondygnacji'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _yearBuiltController,
                  decoration: const InputDecoration(labelText: 'Rok budowy'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _wallMaterialController,
                  decoration: const InputDecoration(
                    labelText: 'Materiał ścian',
                    hintText: 'Cegła, Beton, itp.',
                  ),
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
            ],
          ),
        ] else ...[
          if (building['buildingType'] != null)
            _buildDataRow('Typ budynku', building['buildingType'].toString()),
          if (building['usableArea'] != null)
            _buildDataRow('Powierzchnia użytkowa', '${building['usableArea']} m²'),
          if (building['numberOfFloors'] != null)
            _buildDataRow('Liczba kondygnacji', building['numberOfFloors'].toString()),
          if (building['yearBuilt'] != null)
            _buildDataRow('Rok budowy', building['yearBuilt'].toString()),
          if (building['wallMaterial'] != null)
            _buildDataRow('Materiał ścian', building['wallMaterial'].toString()),
        ],
      ],
    );
  }

  Widget _buildHeatingSection(BuildContext context, InterviewModel interview, bool isEditMode) {
    final heating = interview.heating ?? {};
    
    return _buildSection(
      context,
      'Ogrzewanie',
      Icons.thermostat,
      [
        if (isEditMode) ...[
          TextFormField(
            controller: _heatingTypeController,
            decoration: const InputDecoration(
              labelText: 'Typ ogrzewania',
              hintText: 'Centralne, Kominkowe, itp.',
            ),
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _heatingSourceController,
            decoration: const InputDecoration(
              labelText: 'Źródło ciepła',
              hintText: 'Gaz, Prąd, Węgiel, itp.',
            ),
            onChanged: (_) => _onFieldChanged(),
          ),
        ] else ...[
          if (heating['type'] != null)
            _buildDataRow('Typ ogrzewania', heating['type'].toString()),
          if (heating['source'] != null)
            _buildDataRow('Źródło ciepła', heating['source'].toString()),
        ],
      ],
    );
  }

  Widget _buildFloorsSection(BuildContext context, InterviewModel interview) {
    if (interview.floors.isEmpty) {
      return _buildSection(
        context,
        'Kondygnacje i pomieszczenia',
        Icons.layers,
        [
          const Text(
            'Brak dodanych kondygnacji',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _addFloor(context, interview.id),
            icon: const Icon(Icons.add),
            label: const Text('Dodaj kondygnację'),
          ),
        ],
      );
    }
    
    return _buildSection(
      context,
      'Kondygnacje (${interview.floors.length})',
      Icons.layers,
      [
        ...interview.floors.asMap().entries.map((entry) {
          final floor = entry.value;
          final floorTypeDisplay = FloorType.fromString(floor.type).displayName;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.layers_outlined),
              title: Text(floorTypeDisplay),
              subtitle: Text('Pow.: ${floor.area} m², Wys.: ${floor.height} m, Pomieszczeń: ${floor.rooms.length}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editFloorFromInterview(context, interview.id, floor),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addFloor(context, interview.id),
          icon: const Icon(Icons.add),
          label: const Text('Dodaj kondygnację'),
        ),
      ],
    );
  }

  Future<void> _addFloor(BuildContext context, String interviewId) async {
    final floor = await Navigator.push<floor_models.FloorModel>(
      context,
      MaterialPageRoute(
        builder: (_) => FloorEditorScreen(interviewId: interviewId),
      ),
    );

    if (floor != null && mounted) {
      try {
        // Pokaż loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Debug: Wypisz dane kondygnacji przed zapisem
        print('🔵 Zapisuję kondygnację:');
        print('📊 Dane: ${floor.toJson()}');

        // Zapisz kondygnację do API
        final service = ref.read(interviewServiceProvider);
        await service.saveFloor(interviewId, floor.toJson());

        if (!mounted) return;
        Navigator.pop(context); // Zamknij loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dodano kondygnację: ${floor.type.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Odśwież dane wywiadu
        ref.invalidate(interviewDetailProvider(interviewId));
      } catch (e) {
        print('❌ BŁĄD ZAPISU KONDYGNACJI:');
        print('Error: $e');
        print('StackTrace: ${StackTrace.current}');
        
        if (!mounted) return;
        Navigator.pop(context); // Zamknij loading
        
        // Pokaż szczegółowy błąd
        String errorMessage = 'Błąd zapisu kondygnacji';
        
        if (e.toString().contains('validation')) {
          errorMessage = 'Błąd walidacji danych:\n${e.toString()}';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Nieprawidłowe dane:\n${e.toString()}';
        } else {
          errorMessage = 'Błąd: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _editFloorFromInterview(BuildContext context, String interviewId, FloorModel floor) async {
    // Konwersja z FloorModel (interview_model) do FloorModel (floor_room_models)
    final editorFloor = floor_models.FloorModel(
      id: floor.id,
      type: floor_models.FloorType.fromString(floor.type),
      area: floor.area,
      height: floor.height,
      rooms: floor.rooms.map((r) => floor_models.RoomModel(
        id: r.id,
        name: r.name,
        area: r.area,
        heated: r.heated,
      )).toList(),
    );

    final updated = await Navigator.push<floor_models.FloorModel>(
      context,
      MaterialPageRoute(
        builder: (_) => FloorEditorScreen(
          interviewId: interviewId,
          floor: editorFloor,
        ),
      ),
    );

    if (updated != null && mounted) {
      try {
        // Pokaż loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Debug: Wypisz dane przed aktualizacją
        print('🔵 Aktualizuję kondygnację:');
        print('📊 ID: ${updated.id}');
        print('📊 Dane: ${updated.toJson()}');

        // Zapisz zmiany do API
        final service = ref.read(interviewServiceProvider);
        await service.saveFloor(interviewId, updated.toJson());

        if (!mounted) return;
        Navigator.pop(context); // Zamknij loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zaktualizowano: ${updated.type.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Odśwież dane wywiadu
        ref.invalidate(interviewDetailProvider(interviewId));
      } catch (e) {
        print('❌ BŁD AKTUALIZACJI KONDYGNACJI:');
        print('Error: $e');
        print('StackTrace: ${StackTrace.current}');
        
        if (!mounted) return;
        Navigator.pop(context); // Zamknij loading
        
        // Pokaż szczegółowy błąd
        String errorMessage = 'Błąd aktualizacji kondygnacji';
        
        if (e.toString().contains('validation')) {
          errorMessage = 'Błąd walidacji danych:\n${e.toString()}';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Nieprawidłowe dane:\n${e.toString()}';
        } else {
          errorMessage = 'Błąd: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildNotesSection(BuildContext context, InterviewModel interview, bool isEditMode) {
    return _buildSection(
      context,
      'Notatki i zgoda RODO',
      Icons.note,
      [
        if (isEditMode) ...[
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Dodatkowe informacje o wywiadzie...',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: _hasConsent ? Colors.green : Colors.orange),
              borderRadius: BorderRadius.circular(8),
              color: _hasConsent ? Colors.green.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
            ),
            child: CheckboxListTile(
              value: _hasConsent,
              onChanged: (value) {
                setState(() {
                  _hasConsent = value ?? false;
                });
                _onFieldChanged();
              },
              title: const Text(
                'Zgoda RODO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Wyrażam zgodę na przetwarzanie moich danych osobowych zgodnie z RODO. Zgoda jest wymagana do wysłania wywiadu.',
                style: TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (!_hasConsent)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zaznacz zgodę RODO, aby móc wysłać wywiad do firmy',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
        ] else ...[
          if (interview.notes != null && interview.notes!.isNotEmpty)
            Text(interview.notes!)
          else
            const Text(
              'Brak notatek',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                interview.consent ? Icons.check_circle : Icons.cancel,
                color: interview.consent ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  interview.consent 
                      ? 'Zgoda RODO została wyrażona' 
                      : 'Brak zgody RODO (wymagane do wysłania)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: interview.consent ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref, InterviewModel interview) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _generatePdf(context, ref, interview.id),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generuj PDF'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEsignOptions(context, ref, interview.id),
              icon: const Icon(Icons.draw),
              label: const Text('Podpis elektroniczny'),
            ),
          ),
          const SizedBox(height: 8),
          if (interview.status == 'APPROVED')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _generateOffer(context, ref, interview.id),
                icon: const Icon(Icons.local_offer),
                label: const Text('Generuj ofertę'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    fontSize: 18,
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

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && mounted) {
      setState(() {
        _visitDateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
      _onFieldChanged();
    }
  }

  Future<void> _scanDocument(BuildContext context, String documentType) async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image == null) return;
      
      if (!mounted) return;
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Rozpoznawanie tekstu...'),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Process OCR
      final ocrService = ref.read(ocrServiceProvider);
      final ocrData = await ocrService.extractData(
        await image.readAsBytes(),
        documentType,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Apply OCR data to form
      _applyOcrData(ocrData, documentType);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rozpoznano dane z dokumentu ($documentType)'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      
      // Try to close loading dialog if it's open
      Navigator.of(context, rootNavigator: true).pop();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd skanowania: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyOcrData(Map<String, dynamic> ocrData, String documentType) {
    setState(() {
      if (documentType == 'ID') {
        // Apply owner data from ID card
        if (ocrData['firstName'] != null) {
          _ownerFirstNameController.text = ocrData['firstName'];
        }
        if (ocrData['lastName'] != null) {
          _ownerLastNameController.text = ocrData['lastName'];
        }
        if (ocrData['pesel'] != null) {
          _ownerPeselController.text = ocrData['pesel'];
        }
      } else if (documentType == 'KW') {
        // Apply building data from KW (księga wieczysta)
        if (ocrData['street'] != null) {
          _streetController.text = ocrData['street'];
        }
        if (ocrData['city'] != null) {
          _cityController.text = ocrData['city'];
        }
        if (ocrData['postalCode'] != null) {
          _postalCodeController.text = ocrData['postalCode'];
        }
        if (ocrData['buildingNumber'] != null) {
          _buildingNumberController.text = ocrData['buildingNumber'];
        }
      }
    });
    
    _onFieldChanged(); // Trigger auto-save
  }

  Future<void> _saveManually(BuildContext context, WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final service = ref.read(interviewServiceProvider);
      final updateData = _buildUpdateData();
      
      await service.updateInterview(widget.interviewId, updateData);
      
      if (mounted) {
        ref.invalidate(interviewDetailProvider(widget.interviewId));
        ref.read(editModeProvider.notifier).state = false; // Exit edit mode
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zmiany zapisane pomyślnie'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd zapisu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT':
        return Colors.grey;
      case 'SUBMITTED':
        return Colors.blue;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PDF_SENT':
        return Colors.blue;
      case 'SIGNED_AUTENTI':
        return Colors.green;
      case 'SIGNED_MANUAL':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitInterview(BuildContext context, WidgetRef ref, String id) async {
    try {
      print('🔵 SUBMIT - Rozpoczynam wysyłanie wywiadu: $id');
      
      // Pobierz aktualny wywiad - użyj when() zamiast .future
      final interviewAsync = ref.read(interviewDetailProvider(id));
      
      interviewAsync.when(
        data: (interview) async {
          print('📊 SUBMIT - Status wywiadu: ${interview.status}');
          print('📊 SUBMIT - Zgoda RODO: ${interview.consent}');
          
          // Walidacja wymaganych danych
          final List<String> missingFields = [];
          
          // Sprawdź zgodę RODO
          if (!interview.consent) {
            missingFields.add('Zgoda RODO (zaznacz w trybie edycji)');
          }
          
          // Sprawdź podstawowe dane
          if (interview.town == null || interview.town!.isEmpty) {
            missingFields.add('Miejscowość');
          }
          
          // Sprawdź dane właściciela
          final ownerData = interview.ownerData ?? {};
          if (ownerData['firstName'] == null || ownerData['firstName'].toString().isEmpty) {
            missingFields.add('Imię właściciela');
          }
          if (ownerData['lastName'] == null || ownerData['lastName'].toString().isEmpty) {
            missingFields.add('Nazwisko właściciela');
          }
          if (ownerData['email'] == null || ownerData['email'].toString().isEmpty) {
            missingFields.add('Email właściciela');
          }
          if (ownerData['phone'] == null || ownerData['phone'].toString().isEmpty) {
            missingFields.add('Telefon właściciela');
          }
          
          // Sprawdź adres budynku
          final address = interview.buildingAddress ?? {};
          if (address['street'] == null || address['street'].toString().isEmpty) {
            missingFields.add('Ulica');
          }
          if (address['city'] == null || address['city'].toString().isEmpty) {
            missingFields.add('Miasto');
          }
          
          // Sprawdź dane techniczne
          final building = interview.buildingCore ?? {};
          if (building['buildingType'] == null || building['buildingType'].toString().isEmpty) {
            missingFields.add('Typ budynku');
          }
          
          print('📊 SUBMIT - Brakujące pola: ${missingFields.length > 0 ? missingFields : "brak"}');
          
          // Jeśli brakuje danych, pokaż komunikat
          if (missingFields.isNotEmpty) {
            if (!mounted) return;
            
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Brakujące dane'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aby wysłać wywiad, uzupełnij następujące pola:'),
                    const SizedBox(height: 12),
                    ...missingFields.map((field) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text('• $field')),
                        ],
                      ),
                    )),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
          
          // Wszystkie dane OK - pokaż dialog potwierdzenia
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Wysłać wywiad?'),
              content: const Text(
                'Czy na pewno chcesz wysłać ten wywiad do firmy?\n\n'
                'Po wysłaniu wywiad będzie oczekiwał na zatwierdzenie.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Wyślij'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            if (!mounted) return;
            
            print('🌐 SUBMIT - Wysyłam do API...');
            
            try {
              final apiClient = ref.read(apiClientProvider);
              final service = InterviewService(apiClient);
              
              print('🌐 SUBMIT - Endpoint: /rep/interviews/$id/submit');
              
              await service.submitInterview(id);
              
              print('✅ SUBMIT - Sukces!');
              
              if (!mounted) return;
              ref.invalidate(interviewDetailProvider(id));
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wywiad wysłany pomyślnie! Oczekuje na zatwierdzenie przez firmę.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            } catch (e, stackTrace) {
              print('❌ SUBMIT - BŁĄD WYSYŁANIA:');
              print('Error: $e');
              print('Error type: ${e.runtimeType}');
              print('StackTrace: $stackTrace');
              
              if (!mounted) return;
              
              // Szczegółowy komunikat błędu
              String errorMessage = 'Błąd wysyłania: $e';
              
              if (e.toString().contains('404')) {
                errorMessage = 'Endpoint nie istnieje (404)\n\nSprawdź czy backend ma endpoint:\nPOST /api/v1/rep/interviews/:id/submit';
              } else if (e.toString().contains('400')) {
                errorMessage = 'Nieprawidłowe dane (400)\n\n$e';
              } else if (e.toString().contains('403')) {
                errorMessage = 'Brak uprawnień (403)\n\nMoże status wywiadu nie pozwala na wysłanie?';
              } else if (e.toString().contains('Validation failed')) {
                errorMessage = 'Błąd walidacji backendu:\n\n$e\n\nSprawdź co wymaga backend w endpoint /submit';
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 8),
                ),
              );
            }
          } else {
            print('ℹ️ SUBMIT - Użytkownik anulował');
          }
        },
        loading: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ładowanie danych wywiadu...')),
            );
          }
        },
        error: (error, stack) {
          print('❌ SUBMIT - Błąd ładowania wywiadu: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Błąd: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      print('❌ SUBMIT - Nieoczekiwany błąd: $e');
      print('StackTrace: $stackTrace');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generatePdf(BuildContext context, WidgetRef ref, String id) async {
    try {
      // Pobierz aktualny wywiad - użyj when() zamiast .future
      final interviewAsync = ref.read(interviewDetailProvider(id));
      
      interviewAsync.when(
        data: (interview) async {
          print('🔵 Rozpoczynam generowanie PDF dla wywiadu: $id');
          print('📊 Status wywiadu: ${interview.status}');
          
          // Sprawdź czy status pozwala na generowanie PDF
          final allowedStatuses = ['APPROVED', 'SUBMITTED', 'PDF_SENT', 'SIGNED_AUTENTI', 'SIGNED_MANUAL_UPLOAD'];
          if (!allowedStatuses.contains(interview.status)) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Nie można wygenerować PDF dla wywiadu o statusie: ${interview.status}\n\nPDF można generować tylko dla wywiadów zatwierdzonych przez firmę.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
            return;
          }
          
          final service = ref.read(interviewServiceProvider);
          print('🌐 Wysyłam request do: ${ApiEndpoints.baseUrl}${ApiEndpoints.interviewPdf(id)}');
          
          try {
            final document = await service.generatePdf(id);
            
            print('✅ PDF wygenerowany pomyślnie: ${document.id}');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF wygenerowany: ${document.displayType}')),
            );
            // Odśwież dane wywiadu
            ref.invalidate(interviewDetailProvider(id));
          } catch (e, stackTrace) {
            print('❌ BŁĄD GENEROWANIA PDF:');
            print('Error: $e');
            print('StackTrace: $stackTrace');
            
            if (!mounted) return;
            
            String errorMessage = 'Błąd generowania PDF: $e';
            
            // Bardziej szczegółowy komunikat błędu
            if (e.toString().contains('Błąd serwera')) {
              errorMessage = 'Błąd serwera (500)\n\n'
                  'Możliwe przyczyny:\n'
                  '• Worker (PDF generator) nie działa na backendzie\n'
                  '• Brakujące dane w wywiadzie\n'
                  '• Problem z kolejką BullMQ\n\n'
                  'Skontaktuj się z administratorem.';
            } else if (e.toString().contains('404')) {
              errorMessage = 'Nie znaleziono wywiadu lub endpoint nie istnieje';
            } else if (e.toString().contains('403')) {
              errorMessage = 'Brak uprawnień do generowania PDF';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 8),
              ),
            );
          }
        },
        loading: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ładowanie danych wywiadu...')),
            );
          }
        },
        error: (error, stack) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Błąd: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      print('❌ BŁĄD:');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEsignOptions(BuildContext context, WidgetRef ref, String interviewId) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Wybierz sposób podpisu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.verified, color: Colors.blue),
                title: const Text('E-podpis (Autenti)'),
                subtitle: const Text('Podpis elektroniczny przez Autenti'),
                onTap: () {
                  Navigator.pop(context);
                  _createAutentiEnvelope(context, ref, interviewId);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.green),
                title: const Text('Podpis ręczny'),
                subtitle: const Text('Podpisano ręcznie w biurze'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadManualSignature(context, ref, interviewId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAutentiEnvelope(BuildContext context, WidgetRef ref, String interviewId) async {
    try {
      final esignService = ref.read(esignServiceProvider);
      final envelope = await esignService.createEnvelope(interviewId: interviewId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('E-podpis utworzony: ${envelope.displayStatus}')),
      );
      ref.invalidate(interviewDetailProvider(interviewId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd tworzenia e-podpisu: $e')),
      );
    }
  }

  Future<void> _uploadManualSignature(BuildContext context, WidgetRef ref, String interviewId) async {
    final controller = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Podpis ręczny'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Potwierdź że dokument został podpisany ręcznie w biurze.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Notatka (opcjonalnie)',
                hintText: 'np. Podpisano w biurze 10.02.2026',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Potwierdź'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        final esignService = ref.read(esignServiceProvider);
        await esignService.uploadManualSignature(
          interviewId: interviewId,
          notes: controller.text.isEmpty ? null : controller.text,
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Podpis ręczny zapisany pomyślnie')),
        );
        ref.invalidate(interviewDetailProvider(interviewId));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd zapisu podpisu: $e')),
        );
      }
    }
  }

  Future<void> _generateOffer(BuildContext context, WidgetRef ref, String interviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generuj ofertę'),
        content: const Text('Czy chcesz wygenerować ofertę dla tego wywiadu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generuj'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        final offerService = ref.read(offerServiceProvider);
        final offer = await offerService.generateOffer(interviewId);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oferta wygenerowana: ${offer.displayStatus}')),
        );
        // Możesz przekierować do ekranu oferty
        // context.push('/offers/${offer.id}');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd generowania oferty: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _buildUpdateData() {
    // Konwersja daty z DD.MM.YYYY na ISO 8601 z UTC timezone
    DateTime? parsedDate;
    if (_visitDateController.text.isNotEmpty) {
      try {
        final parts = _visitDateController.text.split('.');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          // Utwórz jako UTC, żeby toIso8601String() dodało "Z"
          parsedDate = DateTime.utc(year, month, day);
        }
      } catch (e) {
        print('⚠️ Błąd parsowania daty: $e');
      }
    }
    
    final data = <String, dynamic>{
      'town': _townController.text.isEmpty ? null : _townController.text,
      'visitDate': parsedDate?.toIso8601String(),
      'notes': _notesController.text.isEmpty ? '' : _notesController.text,
      'consent': _hasConsent, // Dodaj zgodę RODO
    };
    
    // Dodaj ownerData tylko jeśli jakieś pole jest wypełnione
    if (_ownerFirstNameController.text.isNotEmpty ||
        _ownerLastNameController.text.isNotEmpty ||
        _ownerEmailController.text.isNotEmpty ||
        _ownerPhoneController.text.isNotEmpty ||
        _ownerPeselController.text.isNotEmpty) {
      data['ownerData'] = {
        'firstName': _ownerFirstNameController.text.isEmpty ? null : _ownerFirstNameController.text,
        'lastName': _ownerLastNameController.text.isEmpty ? null : _ownerLastNameController.text,
        'email': _ownerEmailController.text.isEmpty ? null : _ownerEmailController.text,
        'phone': _ownerPhoneController.text.isEmpty ? null : _ownerPhoneController.text,
        'pesel': _ownerPeselController.text.isEmpty ? null : _ownerPeselController.text,
      };
    }
    
    // Dodaj buildingAddress tylko jeśli jakieś pole jest wypełnione
    if (_streetController.text.isNotEmpty ||
        _buildingNumberController.text.isNotEmpty ||
        _postalCodeController.text.isNotEmpty ||
        _cityController.text.isNotEmpty ||
        _voivodeshipController.text.isNotEmpty) {
      data['buildingAddress'] = {
        'street': _streetController.text.isEmpty ? null : _streetController.text,
        'buildingNumber': _buildingNumberController.text.isEmpty ? null : _buildingNumberController.text,
        'postalCode': _postalCodeController.text.isEmpty ? null : _postalCodeController.text,
        'city': _cityController.text.isEmpty ? null : _cityController.text,
        'voivodeship': _voivodeshipController.text.isEmpty ? null : _voivodeshipController.text,
      };
    }
    
    // Dodaj buildingCore tylko jeśli jakieś pole jest wypełnione
    if (_buildingTypeController.text.isNotEmpty ||
        _usableAreaController.text.isNotEmpty ||
        _numberOfFloorsController.text.isNotEmpty ||
        _yearBuiltController.text.isNotEmpty ||
        _wallMaterialController.text.isNotEmpty) {
      data['buildingCore'] = {
        'buildingType': _buildingTypeController.text.isEmpty ? null : _buildingTypeController.text,
        'usableArea': _usableAreaController.text.isEmpty 
            ? null 
            : double.tryParse(_usableAreaController.text),
        'numberOfFloors': _numberOfFloorsController.text.isEmpty
            ? null
            : int.tryParse(_numberOfFloorsController.text),
        'yearBuilt': _yearBuiltController.text.isEmpty
            ? null
            : int.tryParse(_yearBuiltController.text),
        'wallMaterial': _wallMaterialController.text.isEmpty ? null : _wallMaterialController.text,
      };
    }
    
    // Dodaj heating tylko jeśli jakieś pole jest wypełnione
    if (_heatingTypeController.text.isNotEmpty ||
        _heatingSourceController.text.isNotEmpty) {
      data['heating'] = {
        'type': _heatingTypeController.text.isEmpty ? null : _heatingTypeController.text,
        'source': _heatingSourceController.text.isEmpty ? null : _heatingSourceController.text,
      };
    }
    
    return data;
  }
}
