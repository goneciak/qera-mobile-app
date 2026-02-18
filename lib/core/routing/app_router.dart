import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/account/providers/subscription_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/accept_invite_screen.dart';
import '../../features/auth/screens/password_reset_request_screen.dart';
import '../../features/auth/screens/password_reset_confirm_screen.dart';
import '../../features/account/screens/subscription_required_screen.dart';
import '../../features/account/screens/subscription_management_screen.dart';
import '../../features/interviews/screens/interview_list_screen.dart';
import '../../features/interviews/screens/interview_detail_screen.dart';
import '../../features/interviews/screens/interview_wizard_screen.dart';
import '../../features/interviews/screens/interview_edit_screen.dart';
import '../../features/offers/screens/offer_list_screen.dart';
import '../../features/offers/screens/offer_detail_screen.dart';
import '../../features/commissions/screens/commission_list_screen.dart';
import '../../features/products/screens/products_list_screen.dart';
import '../../features/account/screens/account_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/main_navigation_screen.dart';

// Create a notifier for router refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(this._ref) {
    _ref.listen(
      authProvider.select((state) => state.isAuthenticated),
      (_, __) => notifyListeners(),
    );
    _ref.listen(
      subscriptionProvider.select((state) => state.isActive),
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;

  @override
  void dispose() {
    // Provider will handle cleanup
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      // Read values inside redirect (not watch)
      final authState = ref.read(authProvider);
      final subscriptionState = ref.read(subscriptionProvider);
      
      // Skip redirect logic for splash screen
      if (state.matchedLocation == '/splash') {
        return null;
      }
      final isAuthenticated = authState.isAuthenticated;
      final isSubscriptionActive = subscriptionState.isActive;
      
      final isLoginRoute = state.matchedLocation == '/login';
      final isAcceptInviteRoute = state.matchedLocation == '/accept-invite';
      final isPasswordResetRoute = state.matchedLocation.startsWith('/password-reset');
      final isSubscriptionRoute = state.matchedLocation == '/subscription-required';
      final isSubscriptionManagementRoute = state.matchedLocation == '/subscription-management';
      final isAccountRoute = state.matchedLocation == '/account';

      // Routes that don't require authentication
      final publicRoutes = isLoginRoute || isAcceptInviteRoute || isPasswordResetRoute;
      
      // Routes that are accessible even with inactive subscription
      final noSubscriptionRequiredRoutes = isSubscriptionRoute || 
                                           isSubscriptionManagementRoute || 
                                           isAccountRoute;

      // If not authenticated and not on public route, redirect to login
      if (!isAuthenticated && !publicRoutes) {
        return '/login';
      }

      // If authenticated but subscription not active and not on allowed page
      if (isAuthenticated && !isSubscriptionActive && !noSubscriptionRequiredRoutes) {
        return '/subscription-required';
      }

      // If authenticated, has active subscription, but on login/subscription page
      if (isAuthenticated && isSubscriptionActive && (publicRoutes || isSubscriptionRoute)) {
        return '/';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/accept-invite',
        builder: (context, state) => const AcceptInviteScreen(),
      ),
      GoRoute(
        path: '/password-reset-request',
        builder: (context, state) => const PasswordResetRequestScreen(),
      ),
      GoRoute(
        path: '/password-reset-confirm/:token',
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return PasswordResetConfirmScreen(token: token);
        },
      ),
      GoRoute(
        path: '/subscription-required',
        builder: (context, state) => const SubscriptionRequiredScreen(),
      ),
      GoRoute(
        path: '/subscription-management',
        builder: (context, state) => const SubscriptionManagementScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            redirect: (context, state) => '/interviews',
          ),
          GoRoute(
            path: '/interviews',
            builder: (context, state) => const InterviewListScreen(),
          ),
          // WAŻNE: '/interviews/create' musi być PRZED '/interviews/:id'
          GoRoute(
            path: '/interviews/create',
            builder: (context, state) => const InterviewWizardScreen(),
          ),
          GoRoute(
            path: '/interviews/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InterviewDetailScreen(interviewId: id);
            },
          ),
          GoRoute(
            path: '/interviews/:id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InterviewEditScreen(interviewId: id);
            },
          ),
          GoRoute(
            path: '/offers',
            builder: (context, state) => const OfferListScreen(),
          ),
          GoRoute(
            path: '/offers/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OfferDetailScreen(offerId: id);
            },
          ),
          GoRoute(
            path: '/commissions',
            builder: (context, state) => const CommissionListScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsListScreen(),
          ),
        ],
      ),
    ],
  );
  
  ref.onDispose(router.dispose);
  
  return router;
});
