import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/account/providers/subscription_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _statusMessage = 'Inicjalizacja...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _updateStatus(String message, double progress) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _progress = progress;
      });
    }
  }

  Future<void> _initialize() async {
    // Small delay for splash animation
    await Future.delayed(const Duration(milliseconds: 500));
    _updateStatus('Sprawdzanie autentykacji...', 0.2);

    if (!mounted) return;

    try {
      final authState = ref.read(authProvider);

      // If not authenticated from cache, go to login immediately
      if (!authState.isAuthenticated) {
        _updateStatus('Przekierowanie do logowania...', 1.0);
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      // User has cached credentials, try to refresh from API
      _updateStatus('Weryfikacja użytkownika...', 0.4);
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.refreshUser();

      if (!mounted) return;

      final updatedAuthState = ref.read(authProvider);

      // If refresh failed and no longer authenticated, go to login
      if (!updatedAuthState.isAuthenticated) {
        _updateStatus('Sesja wygasła, przekierowanie...', 1.0);
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      // User is authenticated, check subscription
      _updateStatus('Sprawdzanie subskrypcji...', 0.7);
      final subscriptionNotifier = ref.read(subscriptionProvider.notifier);
      await subscriptionNotifier.fetchSubscriptionStatus();

      if (!mounted) return;

      final subscriptionState = ref.read(subscriptionProvider);

      // Check if subscription is active
      if (!subscriptionState.isActive) {
        _updateStatus('Wymagana aktywna subskrypcja...', 1.0);
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          context.go('/subscription-required');
        }
        return;
      }

      // All good, go to home
      _updateStatus('Wszystko gotowe!', 1.0);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        context.go('/interviews');
      }
    } catch (e) {
      // On any error, show message and go to login
      _updateStatus('Błąd inicjalizacji...', 1.0);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.business,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              
              // App name
              const Text(
                'Qera Rep',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sales Representative App',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              
              // Progress indicator
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
