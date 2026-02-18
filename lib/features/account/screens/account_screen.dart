import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/offline_providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/subscription-required');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Offline banner
          if (!isOnline) const OfflineBanner(),
          
          // Content
          Expanded(
            child: ListView(
              children: [
                // User info section
                if (user != null) ...[
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(user.email),
                    subtitle: Text('ID: ${user.id}'),
                  ),
                  const Divider(),
                ],

                // Settings section
                ListTile(
                  leading: const Icon(Icons.subscriptions),
                  title: const Text('Status subskrypcji'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/subscription-management');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Pomoc'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final uri = Uri.parse('https://qera.pl/help');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Kontakt'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final uri = Uri.parse('mailto:support@qera.pl?subject=Pytanie dotyczące aplikacji');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                const Divider(),

                // Logout button
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Wyloguj',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Wylogowanie'),
                        content: const Text('Czy na pewno chcesz się wylogować?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Anuluj'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Wyloguj'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      await ref.read(authProvider.notifier).logout();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
