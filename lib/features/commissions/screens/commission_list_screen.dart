import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/commission_model.dart';
import '../providers/commission_provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/offline_providers.dart';

class CommissionListScreen extends ConsumerWidget {
  const CommissionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commissionsAsync = ref.watch(commissionsProvider);
    final totalCommissions = ref.watch(totalCommissionsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prowizje'),
      ),
      body: Column(
        children: [
          // Offline banner
          if (!isOnline) const OfflineBanner(),
          
          // Total summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Łączne prowizje',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(totalCommissions),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          
          // Commissions list
          Expanded(
            child: commissionsAsync.when(
              data: (commissions) {
                if (commissions.isEmpty) {
                  return const Center(
                    child: Text('Brak prowizji'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(commissionsProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: commissions.length,
                    itemBuilder: (context, index) {
                      final commission = commissions[index];
                      return _buildCommissionCard(context, commission, currencyFormat);
                    },
                  ),
                );
              },
              loading: () => const ListSkeleton(itemCount: 8),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Błąd: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(commissionsProvider),
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

  Widget _buildCommissionCard(
    BuildContext context,
    CommissionModel commission,
    NumberFormat currencyFormat,
  ) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    commission.offerClientName ?? 'Prowizja #${commission.id.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (commission.isPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Opłacona',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Break down
            _buildRow('Prowizja podstawowa', currencyFormat.format(commission.baseCommission)),
            _buildRow('Bonus', currencyFormat.format(commission.bonus)),
            const Divider(),
            _buildRow(
              'Łącznie',
              currencyFormat.format(commission.total),
              bold: true,
            ),
            const SizedBox(height: 8),
            
            Text(
              'Utworzono: ${dateFormat.format(commission.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (commission.paidAt != null)
              Text(
                'Wypłacono: ${dateFormat.format(commission.paidAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
