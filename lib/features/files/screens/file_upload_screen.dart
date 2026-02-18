import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/providers/providers.dart';
import '../models/file_model.dart';

class FileUploadScreen extends ConsumerStatefulWidget {
  final String? interviewId;
  final String? offerId;
  final FileKind defaultKind;

  const FileUploadScreen({
    Key? key,
    this.interviewId,
    this.offerId,
    this.defaultKind = FileKind.photo,
  }) : super(key: key);

  @override
  ConsumerState<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends ConsumerState<FileUploadScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;
  FileKind _selectedKind = FileKind.photo;

  @override
  void initState() {
    super.initState();
    _selectedKind = widget.defaultKind;
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      await _uploadFile(File(photo.path));
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      await _uploadFile(File(image.path));
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      await _uploadFile(File(result.files.single.path!));
    }
  }

  Future<void> _uploadFile(File file) async {
    setState(() => _isUploading = true);

    try {
      final fileService = ref.read(fileServiceProvider);
      
      final uploadedFile = await fileService.uploadFile(
        file,
        kind: _selectedKind,
        filename: file.path.split('/').last,
        interviewId: widget.interviewId,
        offerId: widget.offerId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plik przesłany: ${uploadedFile.sizeFormatted}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, uploadedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj plik'),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Wybierz typ pliku:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<FileKind>(
                    segments: const [
                      ButtonSegment(
                        value: FileKind.photo,
                        label: Text('Zdjęcie'),
                        icon: Icon(Icons.photo_camera),
                      ),
                      ButtonSegment(
                        value: FileKind.document,
                        label: Text('Dokument'),
                        icon: Icon(Icons.description),
                      ),
                      ButtonSegment(
                        value: FileKind.signature,
                        label: Text('Podpis'),
                        icon: Icon(Icons.draw),
                      ),
                    ],
                    selected: {_selectedKind},
                    onSelectionChanged: (Set<FileKind> newSelection) {
                      setState(() => _selectedKind = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Zrób zdjęcie'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Wybierz z galerii'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Wybierz dokument'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
