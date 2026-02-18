import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/subscription_provider.dart';

class SubscriptionManagementScreen extends ConsumerStatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  ConsumerState<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends ConsumerState<SubscriptionManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch subscription status when screen loads
    Future.microtask(() {
      ref.read(subscriptionProvider.notifier).fetchSubscriptionStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarządzanie subskrypcją'),
      ),
      body: subscriptionState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : subscriptionState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Błąd: ${subscriptionState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(subscriptionProvider.notifier)
                              .fetchSubscriptionStatus();
                        },
                        child: const Text('Spróbuj ponownie'),
                      ),
                    ],
                  ),
                )
              : _buildContent(context, subscriptionState),
    );
  }

  Widget _buildContent(BuildContext context, SubscriptionState subscriptionState) {
    final isActive = subscriptionState.isActive;
    final status = subscriptionState.subscription?.status;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status card
          Card(
            color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    isActive ? Icons.check_circle : Icons.warning,
                    size: 64,
                    color: isActive ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isActive ? 'Subskrypcja aktywna' : 'Subskrypcja nieaktywna',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status?.displayName ?? 'Brak statusu',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Benefits section
          const Text(
            'Korzyści z subskrypcji',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefitTile(
            Icons.assignment,
            'Nieograniczone wywiady',
            'Twórz dowolną liczbę wywiadów bez limitów',
          ),
          _buildBenefitTile(
            Icons.attach_money,
            'Prowizje w czasie rzeczywistym',
            'Śledź swoje zarobki na bieżąco',
          ),
          _buildBenefitTile(
            Icons.picture_as_pdf,
            'Generowanie PDF',
            'Eksportuj dokumenty do formatu PDF',
          ),
          _buildBenefitTile(
            Icons.draw,
            'Podpis elektroniczny',
            'Podpisuj dokumenty elektronicznie przez Autenti',
          ),
          const SizedBox(height: 24),

          // Actions
          if (!isActive) ...[
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _activateSubscription,
                icon: const Icon(Icons.credit_card),
                label: const Text('Aktywuj subskrypcję'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(subscriptionProvider.notifier).fetchSubscriptionStatus();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Odśwież status'),
            ),
          ),

          if (isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _manageSubscription,
                icon: const Icon(Icons.settings),
                label: const Text('Zarządzaj subskrypcją'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Contact support
          Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Potrzebujesz pomocy?'),
              subtitle: const Text('Skontaktuj się z naszym wsparciem'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _contactSupport,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitTile(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }

  Future<void> _activateSubscription() async {
    try {
      final checkoutUrl =
          await ref.read(subscriptionProvider.notifier).createCheckoutSession();

      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Po zakończeniu płatności odśwież status subskrypcji'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }

  void _manageSubscription() {
    // In a real app, this would open Stripe customer portal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Portal zarządzania subskrypcją będzie dostępny wkrótce'),
      ),
    );
  }

  Future<void> _contactSupport() async {
    final uri = Uri.parse('mailto:support@qera.pl?subject=Pomoc z subskrypcją');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
