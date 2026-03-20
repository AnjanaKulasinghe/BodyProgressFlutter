import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';
import 'package:body_progress/core/toast_manager.dart';
import 'package:body_progress/services/notification_service.dart';
import 'firebase_options.dart';

// Custom cache manager for aggressive image caching
class CustomCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'customCacheKey';

  static CacheManager? _instance;

  factory CustomCacheManager() {
    _instance ??= CustomCacheManager._();
    return _instance as CustomCacheManager;
  }

  CustomCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 30), // Cache for 30 days
          maxNrOfCacheObjects: 500, // Store up to 500 images
          repo: JsonCacheInfoRepository(databaseName: key),
        ));
}

void main() async {
  print('App starting...');
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter binding initialized');

  try {
    // Lock to portrait orientation
    print('Setting orientation...');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Make status bar transparent
    print('Setting system UI...');
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.appBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Initialize Firebase
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        print('⚠️  Firebase initialization timed out after 30s');
        throw TimeoutException('Firebase initialization timeout');
      },
    );
    print('Firebase initialized');

    // Configure Firestore for online-only mode (critical for write reliability)
    final firestore = FirebaseFirestore.instance;
    firestore.settings = const Settings(
      persistenceEnabled: false,  // Disable offline persistence to prevent queue buildup
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    try {
      await firestore.enableNetwork().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⚠️  Firestore network enable timed out after 15s');
        },
      );
    } catch (e) {
      print('⚠️  Firestore network enable failed: $e');
    }

    // Initialize notification service
    print('Initializing notifications...');
    try {
      await NotificationService().initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️  Notification initialization timed out');
        },
      );
      print('Notifications initialized');
    } catch (e) {
      print('⚠️  Notification initialization failed: $e');
    }

    print('Running app...');
    runApp(const ProviderScope(child: BodyProgressApp()));
  } catch (e, stackTrace) {
    print('Error during app initialization: $e');
    print('Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.appBackground,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BodyProgressApp extends ConsumerWidget {
  const BodyProgressApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = createRouter(ref);

    return MaterialApp.router(
      title: 'Body Progress',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        return ToastOverlay(child: child!);
      },
    );
  }
}
