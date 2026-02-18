import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/offer_model.dart';
import '../providers/offer_provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/offline_providers.dart';

class OfferListScreen extends ConsumerWidget {
  const OfferListScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oferty'),
      ),
      body: Column(
        children: [
          // Offline banner
          if (!isOnline) const OfflineBanner(),
          
          // Offers list
          Expanded(
            child: offersAsync.when(
              data: (offers) {
                if (offers.isEmpty) {
                  return const Center(
                    child: Text('Brak ofert'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(offersProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return _buildOfferCard(context, offer);
                    },
                  ),
                );
              },
              loading: () => const ListSkeleton(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, OfferModel offer) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final offerStatus = OfferStatus.fromString(offer.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/offers/${offer.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Oferta #${offer.id.substring(0, 8)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(offerStatus).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      offer.displayStatus,
                      style: TextStyle(
                        color: _getStatusColor(offerStatus),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                currencyFormat.format(offer.totalPrice),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Utworzono: ${dateFormat.format(offer.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              if (offer.sentAt != null)
                Text(
                  'Wysłano: ${dateFormat.format(offer.sentAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
