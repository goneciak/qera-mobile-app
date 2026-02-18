import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../models/ocr_job_model.dart';

class OcrJobsScreen extends ConsumerWidget {
  const OcrJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zadania OCR'),
      ),
      body: FutureBuilder<List<OcrJobModel>>(
        future: ref.read(ocrServiceProvider).listOcrJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Błąd: ${snapshot.error}'),
            );
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return const Center(
              child: Text('Brak zadań OCR'),
            );
          }

          return ListView.builder(
            itemCount: jobs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _OcrJobCard(job: job);
            },
          );
        },
      ),
    );
  }
}

class _OcrJobCard extends StatelessWidget {
  final OcrJobModel job;

  const _OcrJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(),
          child: Icon(_getStatusIcon(), color: Colors.white),
        ),
        title: Text(job.status.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File ID: ${job.fileId.substring(0, 8)}...'),
            if (job.result != null) Text('Wyników: ${job.extractedFields.length}'),
          ],
        ),
        trailing: job.status.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : job.status.isFailed
                ? const Icon(Icons.error, color: Colors.red)
                : const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (job.status) {
      case OcrJobStatus.completed:
        return Colors.green;
      case OcrJobStatus.failed:
        return Colors.red;
      case OcrJobStatus.processing:
        return Colors.blue;
      case OcrJobStatus.pending:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (job.status) {
      case OcrJobStatus.completed:
        return Icons.check;
      case OcrJobStatus.failed:
        return Icons.close;
      case OcrJobStatus.processing:
        return Icons.sync;
      case OcrJobStatus.pending:
        return Icons.schedule;
    }
  }
}
