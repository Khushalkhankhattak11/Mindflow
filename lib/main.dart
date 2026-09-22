import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'services/app_open_ad_service.dart';
import 'services/service_locator.dart';
import 'services/notification_service.dart';
import 'services/audio_cache_service.dart';
import 'services/connectivity_service.dart';
import 'services/image_cache_service.dart';
import 'services/revenuecat_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/notifications_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/progress_viewmodel.dart';
import 'viewmodels/wellness_plan_viewmodel.dart';
import 'views/auth/splash/splash_view.dart';
import 'views/common/no_internet_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure high-performance RAM image cache limits (100MB / 200 images)
  PaintingBinding.instance.imageCache.maximumSize = 200;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;

  try {
    await setupServiceLocator();
    await locator<NotificationService>().init();
    await locator<AudioCacheService>().init();
    await locator<ConnectivityService>().init();
    await locator<ImageCacheService>().init();
    await locator<RevenueCatService>().init();
    unawaited(locator<ImageCacheService>().precacheAllAppImages());
  } catch (e) {
    debugPrint('Startup service initialization warning: $e');
  }

  try {
    await MobileAds.instance.initialize();
    unawaited(locator<AppOpenAdService>().loadAd());
  } catch (e) {
    debugPrint('MobileAds initialization warning: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ProgressViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
        ChangeNotifierProvider(create: (_) => WellnessPlanViewModel()),
      ],
      child: ValueListenableBuilder<bool>(
        valueListenable: locator<ConnectivityService>().isConnected,
        builder: (context, isConnected, child) {
          final isOffline = !isConnected;

          return MaterialApp(
            title: AppStrings.appName,
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF13101B),
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                surface: AppColors.primaryContainer,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
            builder: (context, child) {
              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  if (isOffline) const NoInternetScreen(),
                ],
              );
            },
            home: const SplashView(),
          );
        },
      ),
    );
  }
}
