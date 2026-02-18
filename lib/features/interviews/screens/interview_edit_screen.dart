import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/interview_model.dart';
import '../providers/interview_provider.dart';
import 'interview_detail_screen.dart';

class InterviewEditScreen extends ConsumerStatefulWidget {
  final String interviewId;

  const InterviewEditScreen({
    super.key,
    required this.interviewId,
  });

  @override
  ConsumerState<InterviewEditScreen> createState() => _InterviewEditScreenState();
}

class _InterviewEditScreenState extends ConsumerState<InterviewEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ownerNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _ownerNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  void _initializeControllers(Interview interview) {
    if (!_isInitialized) {
      _ownerNameController.text = interview.ownerFullName;
      _emailController.text = interview.ownerEmail ?? '';
      _phoneController.text = interview.ownerPhone ?? '';
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Rozdziel imię i nazwisko
      final nameParts = _ownerNameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final data = {
        'ownerData': {
          'firstName': firstName,
          'lastName': lastName,
          'email': _emailController.text.isNotEmpty ? _emailController.text : null,
          'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        },
      };

      await ref.read(interviewListProvider.notifier).updateInterview(widget.interviewId, data);
      ref.invalidate(interviewDetailProvider(widget.interviewId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zaktualizowano'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final interviewAsync = ref.watch(interviewDetailProvider(widget.interviewId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edytuj wywiad'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              onPressed: _saveChanges,
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: interviewAsync.when(
        data: (interviewModel) {
          // Convert InterviewModel to Interview for backward compatibility
          final interview = Interview(
            id: interviewModel.id,
            status: InterviewStatus.fromString(interviewModel.status),
            locality: interviewModel.town,
            visitDate: interviewModel.visitDate,
            ownerFirstName: interviewModel.ownerData?['firstName'],
            ownerLastName: interviewModel.ownerData?['lastName'],
            ownerPhone: interviewModel.ownerData?['phone'],
            ownerEmail: interviewModel.ownerData?['email'],
            buildingStreet: interviewModel.buildingAddress?['street'],
            buildingCity: interviewModel.buildingAddress?['city'],
            usableArea: interviewModel.buildingCore?['usableArea']?.toDouble(),
            yearBuilt: interviewModel.buildingCore?['yearBuilt'],
            createdAt: interviewModel.createdAt,
            updatedAt: interviewModel.updatedAt,
          );
          _initializeControllers(interview);
          return _buildForm();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Błąd: $error'),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _ownerNameController,
            decoration: const InputDecoration(
              labelText: 'Imię i nazwisko właściciela *',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveChanges,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Zapisywanie...' : 'Zapisz zmiany'),
            ),
          ),
        ],
      ),
    );
  }
}
