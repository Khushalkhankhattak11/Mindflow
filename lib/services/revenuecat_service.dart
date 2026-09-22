import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'app_logger.dart';

class RevenueCatSubscriptionData {
  final bool isPremium;
  final String status; // 'active', 'expired', 'none'
  final DateTime? purchaseDate;
  final DateTime? expirationDate;
  final DateTime? originalPurchaseDate;
  final String? planIdentifier;
  final String? store;
  final bool willRenew;

  const RevenueCatSubscriptionData({
    required this.isPremium,
    required this.status,
    this.purchaseDate,
    this.expirationDate,
    this.originalPurchaseDate,
    this.planIdentifier,
    this.store,
    this.willRenew = false,
  });
}

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // Entitlement IDs
  static const String premiumEntitlement = 'premium';

  // Revenue Cat API Keys for MindFlow
  final String _androidApiKey = 'goog_bmrwpqbzXgqGLAGPwheZjwnIxLR';
  final String _iosApiKey = 'appl_YOUR_REVENUECAT_PUBLIC_SDK_KEY';

  // Flags
  bool hasPremiumAccess = false;
  CustomerInfo? _customerInfo;

  CustomerInfo? get customerInfo => _customerInfo;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Callback listener for real-time CustomerInfo changes from RevenueCat
  void Function(CustomerInfo customerInfo)? onCustomerInfoUpdated;

  /// Parse RevenueCat CustomerInfo into structured, normalized subscription data
  RevenueCatSubscriptionData parseSubscriptionData(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.all[premiumEntitlement] ??
        (customerInfo.entitlements.active.isNotEmpty
            ? customerInfo.entitlements.active.values.first
            : (customerInfo.entitlements.all.isNotEmpty
                ? customerInfo.entitlements.all.values.first
                : null));

    bool isActive = entitlement?.isActive ?? customerInfo.entitlements.active.isNotEmpty;

    DateTime? expirationDate;
    if (entitlement?.expirationDate != null) {
      expirationDate = DateTime.tryParse(entitlement!.expirationDate!);
    } else if (customerInfo.latestExpirationDate != null) {
      expirationDate = DateTime.tryParse(customerInfo.latestExpirationDate!);
    }

    // Auto-lock check: if the expiration date has passed, it is strictly expired
    if (isActive && expirationDate != null && DateTime.now().isAfter(expirationDate)) {
      isActive = false;
    }

    DateTime? purchaseDate;
    if (entitlement?.latestPurchaseDate != null) {
      purchaseDate = DateTime.tryParse(entitlement!.latestPurchaseDate);
    }

    DateTime? originalPurchaseDate;
    if (entitlement?.originalPurchaseDate != null) {
      originalPurchaseDate = DateTime.tryParse(entitlement!.originalPurchaseDate);
    } else if (customerInfo.originalPurchaseDate != null) {
      originalPurchaseDate = DateTime.tryParse(customerInfo.originalPurchaseDate!);
    }

    String? plan = entitlement?.productIdentifier;
    if (plan == null && customerInfo.activeSubscriptions.isNotEmpty) {
      plan = customerInfo.activeSubscriptions.first;
    } else if (plan == null && customerInfo.allPurchasedProductIdentifiers.isNotEmpty) {
      plan = customerInfo.allPurchasedProductIdentifiers.first;
    }

    String? store = entitlement?.store.name;
    bool willRenew = entitlement?.willRenew ?? false;

    String status;
    if (isActive) {
      status = 'active';
    } else if (customerInfo.allPurchasedProductIdentifiers.isNotEmpty || entitlement != null) {
      status = 'expired';
    } else {
      status = 'none';
    }

    return RevenueCatSubscriptionData(
      isPremium: isActive,
      status: status,
      purchaseDate: purchaseDate,
      expirationDate: expirationDate,
      originalPurchaseDate: originalPurchaseDate,
      planIdentifier: plan,
      store: store,
      willRenew: willRenew,
    );
  }

  void _handleCustomerInfoUpdate(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    final parsed = parseSubscriptionData(customerInfo);
    hasPremiumAccess = parsed.isPremium;
    AppLogger.i(
      'RevenueCat CustomerInfo updated: hasPremiumAccess=$hasPremiumAccess | status=${parsed.status} | expires=${parsed.expirationDate}',
    );
    onCustomerInfoUpdated?.call(customerInfo);
  }

  // ---------------------------
  // INIT
  // ---------------------------
  Future<void> init({String? userId}) async {
    try {
      if (kIsWeb) return;

      final isConfigured = await Purchases.isConfigured;
      if (isConfigured) {
        _isInitialized = true;
        AppLogger.i('RevenueCat is already configured.');
        Purchases.addCustomerInfoUpdateListener((customerInfo) {
          _handleCustomerInfoUpdate(customerInfo);
        });
        return;
      }

      final apiKey = Platform.isAndroid ? _androidApiKey : _iosApiKey;
      if (apiKey.contains('YOUR_REVENUECAT')) {
        AppLogger.w('RevenueCat SDK Key is not configured yet. Skipping configuration.');
        return;
      }

      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      PurchasesConfiguration configuration;
      if (userId == null) {
        AppLogger.i('Starting configuration without userId');
        configuration = PurchasesConfiguration(apiKey);
      } else {
        AppLogger.i('Starting configuration with userId: $userId');
        configuration = PurchasesConfiguration(apiKey)..appUserID = userId;
      }

      await Purchases.configure(configuration);
      _isInitialized = true;
      AppLogger.i('RevenueCat initialized successfully for MindFlow.');

      // Listen to real-time subscription lifecycle updates (purchases, renewals, cancellations, expiries)
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _handleCustomerInfoUpdate(customerInfo);
      });

      final currentAppUserId = await Purchases.appUserID;
      AppLogger.d('Current RevenueCat user ID: $currentAppUserId');

      await syncPurchases();
    } catch (e, stackTrace) {
      AppLogger.e('RevenueCat initialization error', e, stackTrace);
    }
  }

  // ---------------------------
  // Offerings
  // ---------------------------
  Future<Offerings?> getOfferings() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (!_isInitialized) {
        AppLogger.w('RevenueCat not initialized. Skipping getOfferings.');
        return null;
      }
      final offerings = await Purchases.getOfferings();
      AppLogger.i('================ RevenueCat Offerings Log ================');
      AppLogger.i('Current Offering Identifier: ${offerings.current?.identifier}');
      if (offerings.current != null) {
        for (final pkg in offerings.current!.availablePackages) {
          AppLogger.i(
            '📦 Package: ${pkg.identifier} | Type: ${pkg.packageType} | Product ID: ${pkg.storeProduct.identifier} | Price: ${pkg.storeProduct.priceString}',
          );
        }
      } else {
        AppLogger.w('No current offering found in RevenueCat Dashboard.');
      }
      AppLogger.i('===========================================================');
      return offerings;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching offerings', e, stackTrace);
      return null;
    }
  }

  // -----------------------------------------
  // Purchase Package
  // -----------------------------------------
  Future<bool> makePurchase(Package package) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (!_isInitialized) return false;

      AppLogger.i('🛒 Attempting purchase for Package: ${package.identifier} (Product: ${package.storeProduct.identifier})');
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _handleCustomerInfoUpdate(result.customerInfo);

      AppLogger.i('🎉 Purchase successful! Active entitlements: ${result.customerInfo.entitlements.active.keys.toList()} | hasPremiumAccess: $hasPremiumAccess');
      return hasPremiumAccess;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        AppLogger.i('User cancelled the purchase sheet.');
        return false;
      }
      AppLogger.e('Error purchasing package ${package.identifier}', e);
      return false;
    } catch (e, stackTrace) {
      AppLogger.e('Error making purchase for package ${package.identifier}', e, stackTrace);
      return false;
    }
  }

  // -----------------------------------------
  // Purchase StoreProduct
  // -----------------------------------------
  Future<bool> purchaseStoreProduct(StoreProduct product) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (!_isInitialized) return false;

      AppLogger.i('🛒 Attempting purchase for StoreProduct: ${product.identifier}');
      final result = await Purchases.purchase(PurchaseParams.storeProduct(product));
      _handleCustomerInfoUpdate(result.customerInfo);

      AppLogger.i('🎉 Product purchase successful! Active entitlements: ${result.customerInfo.entitlements.active.keys.toList()} | hasPremiumAccess: $hasPremiumAccess');
      return hasPremiumAccess;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        AppLogger.i('User cancelled the purchase sheet.');
        return false;
      }
      AppLogger.e('Error purchasing store product ${product.identifier}', e);
      return false;
    } catch (e, stackTrace) {
      AppLogger.e('Error making purchase for product ${product.identifier}', e, stackTrace);
      return false;
    }
  }

  // -----------------------------------------
  // Get Products for Android / Generic
  // -----------------------------------------
  Future<List<StoreProduct>> getProductsForAndroid() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (!_isInitialized) return [];

      await syncPurchases();
      final products = await Purchases.getProducts([
        'mindflow_premium:weekly',
        'mindflow_premium:yearly',
        'mindflow_premium',
        'weekly',
        'yearly',
      ]);

      AppLogger.i('================ Direct Store Products Log ================');
      AppLogger.i('Fetched ${products.length} products directly from store:');
      for (final prod in products) {
        AppLogger.i('🛍️ Product ID: ${prod.identifier} | Title: ${prod.title} | Price: ${prod.priceString}');
      }
      AppLogger.i('===========================================================');
      return products;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching Android products', e, stackTrace);
      return [];
    }
  }

  /// Generic store products lookup helper
  Future<List<StoreProduct>> getProducts(List<String> identifiers) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (!_isInitialized) return [];

      final products = await Purchases.getProducts(identifiers);
      AppLogger.i('Fetched ${products.length} store products for $identifiers');
      return products;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching store products', e, stackTrace);
      return [];
    }
  }

  // -----------------------------------------
  // Restore Purchases
  // -----------------------------------------
  Future<bool> restorePurchases() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (!_isInitialized) return false;

      AppLogger.i('🔄 Restoring purchases...');
      final restoredInfo = await Purchases.restorePurchases();
      _handleCustomerInfoUpdate(restoredInfo);

      AppLogger.i('🔄 Restored entitlements: ${restoredInfo.entitlements.active.keys.toList()} | hasPremiumAccess: $hasPremiumAccess');
      return hasPremiumAccess;
    } catch (e, stackTrace) {
      AppLogger.e('Error restoring purchases', e, stackTrace);
      return false;
    }
  }

  // -----------------------------------------
  // Get Customer Info
  // -----------------------------------------
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (!_isInitialized) return null;

      final info = await Purchases.getCustomerInfo();
      _handleCustomerInfoUpdate(info);

      return info;
    } catch (e, stackTrace) {
      AppLogger.e('Error retrieving customer info', e, stackTrace);
      return null;
    }
  }

  // -----------------------------------------
  // Check Premium Entitlement
  // -----------------------------------------
  Future<bool> isUserPremium() async {
    try {
      final info = await getCustomerInfo();
      if (info == null) return false;
      return info.entitlements.all[premiumEntitlement]?.isActive ??
          info.entitlements.active.isNotEmpty;
    } catch (e, stackTrace) {
      AppLogger.e('Error checking premium status', e, stackTrace);
      return false;
    }
  }

  // -----------------------------------------
  // Identify User (Login)
  // -----------------------------------------
  Future<void> identifyUser(String userId) async {
    try {
      if (!_isInitialized) {
        await init(userId: userId);
        return;
      }
      AppLogger.i('Identifying user with RevenueCat: $userId');
      final loginResult = await Purchases.logIn(userId);
      _handleCustomerInfoUpdate(loginResult.customerInfo);

      AppLogger.i('User identified with RevenueCat: $userId | hasPremiumAccess: $hasPremiumAccess');
    } catch (e, stackTrace) {
      AppLogger.e('Error identifying user with RevenueCat', e, stackTrace);
    }
  }

  // -----------------------------------------
  // Sync Purchases
  // -----------------------------------------
  Future<void> syncPurchases() async {
    try {
      if (!_isInitialized) return;
      await Purchases.syncPurchases();
    } catch (_) {}
  }

  // -----------------------------------------
  // Logout
  // -----------------------------------------
  Future<void> logout() async {
    try {
      if (!_isInitialized) return;
      final info = await Purchases.getCustomerInfo();
      if (info.originalAppUserId.startsWith(r'$RCAnonymousID:')) {
        AppLogger.d('Current user is anonymous. Skipping RevenueCat logout.');
        return;
      }
      AppLogger.i('Logging out of RevenueCat');
      await Purchases.logOut();
      hasPremiumAccess = false;
      _customerInfo = null;
    } catch (e, stackTrace) {
      AppLogger.e('Error logging out from RevenueCat', e, stackTrace);
    }
  }
}
