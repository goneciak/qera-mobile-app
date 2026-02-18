import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/interview_wizard_provider.dart';
import '../../../files/screens/file_upload_screen.dart';
import '../../../files/models/file_model.dart';

class PhotosStep extends ConsumerStatefulWidget {
  const PhotosStep({super.key});

  @override
  ConsumerState<PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends ConsumerState<PhotosStep> {
  List<FileModel> _uploadedPhotos = [];

  Future<void> _addPhoto() async {
    final wizardState = ref.read(interviewWizardProvider);
    
    // Save draft first if not exists
    if (wizardState.interviewId == null) {
      await ref.read(interviewWizardProvider.notifier).saveDraft();
    }
    
    final interviewId = ref.read(interviewWizardProvider).interviewId;

    if (interviewId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie można dodać zdjęć - zapisz szkic najpierw')),
      );
      return;
    }

    if (!mounted) return;
    final photo = await Navigator.push<FileModel>(
      context,
      MaterialPageRoute(
        builder: (_) => FileUploadScreen(
          interviewId: interviewId,
          defaultKind: FileKind.photo,
        ),
      ),
    );

    if (photo != null && mounted) {
      setState(() {
        _uploadedPhotos.add(photo);
      });

      // Update wizard state
      ref.read(interviewWizardProvider.notifier).updateFormData({
        'photoIds': _uploadedPhotos.map((p) => p.id).toList(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dodano zdjęcie (${photo.sizeFormatted})'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _uploadedPhotos.removeAt(index);
    });

    // Update wizard state
    ref.read(interviewWizardProvider.notifier).updateFormData({
      'photoIds': _uploadedPhotos.map((p) => p.id).toList(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usunięto zdjęcie')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zdjęcia budynku',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Dodaj zdjęcia budynku (opcjonalnie)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 24),

        // Photos grid
        if (_uploadedPhotos.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.camera_alt, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Brak dodanych zdjęć',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _uploadedPhotos.length,
            itemBuilder: (context, index) {
              final photo = _uploadedPhotos[index];
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image, size: 32, color: Colors.grey),
                          const SizedBox(height: 4),
                          Text(
                            photo.sizeFormatted,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _removePhoto(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              );
            },
          ),

        const SizedBox(height: 24),

        // Add button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addPhoto,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Dodaj zdjęcie'),
          ),
        ),

        const SizedBox(height: 16),

        // Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Zdjęcia pomogą w przygotowaniu dokładnej oferty',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
