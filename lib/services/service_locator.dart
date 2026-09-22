import 'package:get_it/get_it.dart';
import 'firebase_service.dart';
import 'auth_service.dart';
import 'fcm_service.dart';
import 'device_service.dart';
import 'app_open_ad_service.dart';
import 'notification_service.dart';
import 'audio_cache_service.dart';
import 'connectivity_service.dart';
import 'image_cache_service.dart';
import 'revenuecat_service.dart';
import '../repositories/auth_repository.dart';
import '../repositories/onboarding_repository.dart';
import '../repositories/user_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/notifications_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/progress_viewmodel.dart';
import '../viewmodels/wellness_plan_viewmodel.dart';

final locator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 1. Initialize Firebase Core Service
  final firebaseService = FirebaseService();
  await firebaseService.init();
  locator.registerSingleton<FirebaseService>(firebaseService);

  // 2. Register low-level Firebase Services
  locator.registerSingleton<AuthService>(
    AuthService(firebaseService: firebaseService),
  );
  locator.registerSingleton<FcmService>(
    FcmService(firebaseService: firebaseService),
  );
  locator.registerSingleton<DeviceService>(DeviceService());
  locator.registerSingleton<AppOpenAdService>(AppOpenAdService());
  locator.registerSingleton<NotificationService>(NotificationService());
  locator.registerSingleton<AudioCacheService>(AudioCacheService());
  locator.registerSingleton<ConnectivityService>(ConnectivityService());
  locator.registerSingleton<ImageCacheService>(ImageCacheService());
  locator.registerSingleton<RevenueCatService>(RevenueCatService());

  // 3. Register Repositories
  locator.registerSingleton<UserRepository>(UserRepository());
  locator.registerSingleton<AuthRepository>(
    AuthRepository(
      firebaseService: firebaseService,
      authService: locator<AuthService>(),
      fcmService: locator<FcmService>(),
    ),
  );
  locator.registerSingleton<OnboardingRepository>(
    OnboardingRepository(
      firebaseService: firebaseService,
      deviceService: locator<DeviceService>(),
    ),
  );

  // 4. Register ViewModels
  locator.registerFactory<AuthViewModel>(() => AuthViewModel());
  locator.registerFactory<HomeViewModel>(() => HomeViewModel());
  locator.registerFactory<ProgressViewModel>(() => ProgressViewModel());
  locator.registerFactory<ProfileViewModel>(() => ProfileViewModel());
  locator.registerFactory<NotificationsViewModel>(() => NotificationsViewModel());
  locator.registerFactory<WellnessPlanViewModel>(() => WellnessPlanViewModel());
}
