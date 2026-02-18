import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/offer_model.dart';
import '../providers/offer_provider.dart';
import '../../../core/providers/providers.dart' hide offerServiceProvider;
import '../../documents/screens/pdf_viewer_screen.dart';

class OfferDetailScreen extends ConsumerWidget {
  final String offerId;

  const OfferDetailScreen({
    super.key,
    required this.offerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły oferty'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _viewPdf(context, ref, offerId),
          ),
        ],
      ),
      body: offersAsync.when(
        data: (offers) {
          final offer = offers.firstWhere(
            (o) => o.id == offerId,
            orElse: () => offers.first,
          );
          return _buildContent(context, ref, offer);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Błąd: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(offersProvider),
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewPdf(BuildContext context, WidgetRef ref, String offerId) async {
    try {
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
                  Text('Wczytywanie PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Get PDF document
      final documentService = ref.read(documentServiceProvider);
      final pdf = await documentService.getOfferPdf(offerId);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      if (pdf == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brak wygenerowanego PDF dla tej oferty. Wygeneruj PDF najpierw.')),
        );
        return;
      }

      // Navigate to PDF viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(document: pdf),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, OfferModel offer) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final offerStatus = OfferStatus.fromString(offer.status);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.all(16),
            color: _getStatusColor(offerStatus).withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  offer.displayStatus,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _getStatusColor(offerStatus),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          // Client info
          _buildSection(
            context,
            'Klient',
            Icons.person,
            [
              _buildDataRow('Nazwa', offer.clientName),
            ],
          ),

          // Price info
          _buildSection(
            context,
            'Wycena',
            Icons.attach_money,
            [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Łączna wartość',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(offer.totalPrice),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          // Timeline
          _buildSection(
            context,
            'Historia',
            Icons.timeline,
            [
              _buildDataRow('Utworzono', dateFormat.format(offer.createdAt)),
              if (offer.sentAt != null)
                _buildDataRow('Wysłano', dateFormat.format(offer.sentAt!)),
            ],
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (offerStatus == OfferStatus.draft)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _sendOffer(context, ref, offer.id),
                      icon: const Icon(Icons.send),
                      label: const Text('Wyślij ofertę'),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _viewPdf(context, ref, offer.id),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Pokaż PDF'),
                  ),
                ),
                if (offerStatus == OfferStatus.sent ||
                    offerStatus == OfferStatus.clientAccepted)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _shareOffer(context, offer),
                        icon: const Icon(Icons.share),
                        label: const Text('Udostępnij'),
                      ),
                    ),
                  ),
              ],
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
            width: 100,
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

  Color _getStatusColor(OfferStatus status) {
    switch (status) {
      case OfferStatus.draft:
        return Colors.grey;
      case OfferStatus.sent:
        return Colors.blue;
      case OfferStatus.clientAccepted:
        return Colors.green;
      case OfferStatus.rejected:
        return Colors.red;
      case OfferStatus.approved:
        return Colors.green;
    }
  }

  Future<void> _sendOffer(BuildContext context, WidgetRef ref, String offerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wysłać ofertę?'),
        content: const Text('Czy na pewno chcesz wysłać tę ofertę do klienta?'),
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

    if (confirmed == true && context.mounted) {
      try {
        final offerService = ref.read(offerServiceProvider);
        await offerService.sendOffer(offerId);

        if (context.mounted) {
          ref.invalidate(offersProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oferta wysłana do klienta'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd wysyłania oferty: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareOffer(BuildContext context, OfferModel offer) async {
    try {
      final text = '''
📋 Oferta dla: ${offer.clientName}

💰 Wartość: ${NumberFormat.currency(locale: 'pl_PL', symbol: 'zł').format(offer.totalPrice)}
📅 Data: ${DateFormat('dd.MM.yyyy').format(offer.createdAt)}
✅ Status: ${offer.displayStatus}

Oferta wygenerowana przez aplikację Qera Rep
      '''.trim();

      await Share.share(
        text,
        subject: 'Oferta - ${offer.clientName}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd udostępniania: $e')),
        );
      }
    }
  }
}
