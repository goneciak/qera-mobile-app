import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../account/models/subscription_model.dart';
import '../../../core/providers/providers.dart';

// Re-export subscription service provider
final subscriptionServiceProviderAlias = Provider((ref) {
  return ref.watch(subscriptionServiceProvider);
});

class SubscriptionRequiredScreen extends ConsumerStatefulWidget {
  const SubscriptionRequiredScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionRequiredScreen> createState() =>
      _SubscriptionRequiredScreenState();
}

class _SubscriptionRequiredScreenState
    extends ConsumerState<SubscriptionRequiredScreen> {
  bool _isRefreshing = false;
  SubscriptionModel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final service = ref.read(subscriptionServiceProvider);
      final sub = await service.getSubscriptionStatus();
      setState(() => _subscription = sub);
    } catch (e) {
      // Ignore errors - status będzie null
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);
    await _loadSubscription();
    setState(() => _isRefreshing = false);

    if (_subscription?.status.isActive == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subskrypcja aktywna! Odświeżam aplikację...'),
            backgroundColor: Colors.green,
          ),
        );
        // TODO: Navigate to main app
      }
    }
  }

  Future<void> _activateSubscription() async {
    try {
      final service = ref.read(subscriptionServiceProvider);
      final response = await service.createCheckoutSession();
      
      final uri = Uri.parse(response.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Po zakończeniu płatności wróć i naciśnij "Odśwież status"'),
              duration: Duration(seconds: 5),
            ),
          );
        }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subskrypcja wymagana'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Logout
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status indicator
            _buildStatusCard(),
            const SizedBox(height: 32),

            // Benefits
            const Text(
              'Korzyści z subskrypcji:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBenefit(
              Icons.assignment,
              'Nieograniczone wywiady techniczne',
              'Twórz i zarządzaj wywiadami bez limitów',
            ),
            _buildBenefit(
              Icons.description,
              'Automatyczne generowanie ofert',
              'PDF + e-podpis w kilka chwil',
            ),
            _buildBenefit(
              Icons.attach_money,
              'Podgląd prowizji w czasie rzeczywistym',
              'Śledź swoje zarobki na bieżąco',
            ),
            const SizedBox(height: 32),

            // Activate button
            ElevatedButton.icon(
              onPressed: _activateSubscription,
              icon: const Icon(Icons.credit_card),
              label: const Text('Aktywuj subskrypcję (Stripe)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Refresh status button
            OutlinedButton.icon(
              onPressed: _isRefreshing ? null : _refreshStatus,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Opłacone przelewem? Sprawdź status'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            // Contact
            const Divider(),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _contactCompany,
              icon: const Icon(Icons.support_agent),
              label: const Text('Skontaktuj się z firmą'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _subscription?.status ?? SubscriptionStatus.inactive;
    final statusColor = status.isActive ? Colors.green : Colors.red;

    return Card(
      color: statusColor.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              status.isActive ? Icons.check_circle : Icons.block,
              size: 48,
              color: statusColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${status.displayName}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            if (_subscription?.validUntil != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ważna do: ${_formatDate(_subscription!.validUntil!)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (_subscription?.providerDisplayName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Typ: ${_subscription!.providerDisplayName}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactCompany() async {
    // TODO: Add company contact details
    const email = 'support@qera.pl';
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
