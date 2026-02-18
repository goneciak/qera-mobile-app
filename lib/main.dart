import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/routing/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/error_tracking_service.dart';
import 'core/sync/sync_service.dart';
import 'core/storage/secure_storage.dart';
import 'core/providers/providers.dart';

// Flaga trybu testowego - ustaw na false gdy masz Firebase/Sentry skonfigurowane
const bool kTestMode = true;
const String kSentryDsn = ''; // Dodaj swój Sentry DSN tutaj

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SecureStorage
  final storage = await SecureStorage.init();
  
  // Inicjalizacja z lub bez Sentry
  if (kTestMode || kSentryDsn.isEmpty) {
    // Tryb testowy - bez Sentry
    debugPrint('🧪 Running in TEST MODE (no Sentry/Firebase)');
    await _initializeApp(storage);
  } else {
    // Produkcja - z Sentry
    await SentryFlutter.init(
      (options) {
        options.dsn = kSentryDsn;
        options.tracesSampleRate = 1.0;
        options.environment = kDebugMode ? 'development' : 'production';
        options.enableAutoSessionTracking = true;
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;
        options.beforeSend = (event, hint) {
          // Filter out sensitive data before sending to Sentry
          return event;
        };
      },
      appRunner: () async => await _initializeApp(storage),
    );
  }
}

Future<void> _initializeApp(SecureStorage storage) async {
  // Initialize Firebase tylko jeśli nie jesteśmy w trybie testowym
  if (!kTestMode) {
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized');
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
      if (!kTestMode) {
        ErrorTrackingService.captureException(e, hint: 'Firebase initialization failed');
      }
    }
  } else {
    debugPrint('⏭️  Skipping Firebase initialization (test mode)');
  }

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize notifications
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
      
      // Initialize sync service
      final syncService = ref.read(syncServiceProvider);
      await syncService.initialize();
      
      // Set up analytics
      ErrorTrackingService.addBreadcrumb(
        message: 'App initialized',
        category: 'lifecycle',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Service initialization error: $e');
      ErrorTrackingService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Service initialization failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Qera Rep',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
