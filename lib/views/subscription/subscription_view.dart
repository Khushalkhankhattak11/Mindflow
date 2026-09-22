import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../services/revenuecat_service.dart';
import '../../services/service_locator.dart';
import '../../viewmodels/home_viewmodel.dart';

class SubscriptionView extends StatefulWidget {
  final HomeViewModel viewModel;

  const SubscriptionView({super.key, required this.viewModel});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  String _selectedPackage = 'yearly'; // 'weekly' or 'yearly'
  bool _isLoading = false;
  Package? _weeklyPackage;
  Package? _yearlyPackage;
  StoreProduct? _weeklyStoreProduct;
  StoreProduct? _yearlyStoreProduct;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final rcService = locator<RevenueCatService>();
      
      // 1. Fetch RevenueCat Offerings configured in dashboard for MindFlow
      final offerings = await rcService.getOfferings().timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );

      if (offerings != null) {
        final currentOffering = offerings.current ?? offerings.all.values.firstOrNull;
        if (currentOffering != null) {
          Package? weekly = currentOffering.weekly;
          Package? yearly = currentOffering.annual;

          if (weekly == null || yearly == null) {
            for (final package in currentOffering.availablePackages) {
              final id = package.identifier.toLowerCase();
              final prodId = package.storeProduct.identifier.toLowerCase();

              if (package.packageType == PackageType.weekly ||
                  id.contains('weekly') ||
                  id.contains('week') ||
                  prodId.contains('weekly') ||
                  prodId.contains('week')) {
                weekly ??= package;
              } else if (package.packageType == PackageType.annual ||
                  id.contains('yearly') ||
                  id.contains('year') ||
                  id.contains('annual') ||
                  prodId.contains('yearly') ||
                  prodId.contains('year')) {
                yearly ??= package;
              }
            }
          }

          if (mounted) {
            setState(() {
              _weeklyPackage = weekly;
              _yearlyPackage = yearly;
              if (weekly != null) _weeklyStoreProduct = weekly.storeProduct;
              if (yearly != null) _yearlyStoreProduct = yearly.storeProduct;
            });
          }
        }
      }

      // 2. Fallback: Direct Store Products lookup (Google Play Console base plans: weekly & yearly)
      if (_weeklyPackage == null && _yearlyPackage == null) {
        final productIds = [
          'mindflow_premium:weekly',
          'mindflow_premium:yearly',
          'mindflow_premium',
          'weekly',
          'yearly',
        ];

        final storeProducts = await rcService.getProducts(productIds).timeout(
          const Duration(seconds: 4),
          onTimeout: () => [],
        );

        if (storeProducts.isNotEmpty) {
          StoreProduct? weeklyProd;
          StoreProduct? yearlyProd;

          for (final prod in storeProducts) {
            final id = prod.identifier.toLowerCase();
            if (id.contains('weekly') || id.contains('week')) {
              weeklyProd ??= prod;
            } else if (id.contains('yearly') || id.contains('annual') || id.contains('year')) {
              yearlyProd ??= prod;
            }
          }

          if (mounted) {
            setState(() {
              _weeklyStoreProduct = weeklyProd;
              _yearlyStoreProduct = yearlyProd;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading RevenueCat offerings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRestorePurchases() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final isRestored = await locator<RevenueCatService>()
          .restorePurchases()
          .timeout(const Duration(seconds: 15), onTimeout: () => false);

      if (!mounted) return;

      if (isRestored) {
        final rcService = locator<RevenueCatService>();
        final custInfo = rcService.customerInfo;
        final now = DateTime.now();

        if (custInfo != null) {
          final parsed = rcService.parseSubscriptionData(custInfo);
          await widget.viewModel.setPremiumStatus(
            true,
            purchaseDate: parsed.purchaseDate ?? now,
            expirationDate: parsed.expirationDate ?? now.add(const Duration(days: 365)),
            subscriptionStatus: 'active',
            subscriptionPlan: parsed.planIdentifier,
            subscriptionStore: parsed.store,
            willRenew: parsed.willRenew,
          );
        } else {
          await widget.viewModel.setPremiumStatus(
            true,
            purchaseDate: now,
            expirationDate: now.add(const Duration(days: 365)),
            subscriptionStatus: 'active',
          );
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active subscription found to restore.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore purchases: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSubscribe() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final defaultExpirationDate = _selectedPackage == 'weekly'
          ? now.add(const Duration(days: 7))
          : now.add(const Duration(days: 365));

      final Package? packageToBuy = _selectedPackage == 'weekly' ? _weeklyPackage : _yearlyPackage;
      final StoreProduct? productToBuy = _selectedPackage == 'weekly' ? _weeklyStoreProduct : _yearlyStoreProduct;

      bool isPurchaseSuccessful = false;
      final rcService = locator<RevenueCatService>();

      // 1. Purchase using RevenueCat Package (Triggers native Google Play Sheet)
      if (packageToBuy != null) {
        isPurchaseSuccessful = await rcService
            .makePurchase(packageToBuy)
            .timeout(const Duration(seconds: 60), onTimeout: () => false);
      }
      // 2. Purchase using Direct StoreProduct (Triggers native Google Play Sheet)
      else if (productToBuy != null) {
        isPurchaseSuccessful = await rcService
            .purchaseStoreProduct(productToBuy)
            .timeout(const Duration(seconds: 60), onTimeout: () => false);
      }
      // 3. Fallback: fetch store product dynamically and launch native sheet
      else {
        final productIds = [
          'mindflow_premium:weekly',
          'mindflow_premium:yearly',
          'mindflow_premium',
          'weekly',
          'yearly',
        ];

        final storeProducts = await rcService.getProducts(productIds);
        if (storeProducts.isNotEmpty) {
          final targetProd = storeProducts.firstWhere(
            (p) => _selectedPackage == 'weekly' 
                ? (p.identifier.toLowerCase().contains('weekly') || p.identifier.toLowerCase().contains('week'))
                : (p.identifier.toLowerCase().contains('yearly') || p.identifier.toLowerCase().contains('annual') || p.identifier.toLowerCase().contains('year')),
            orElse: () => storeProducts.first,
          );

          isPurchaseSuccessful = await rcService.purchaseStoreProduct(targetProd);
        } else {
          // Simulation fallback if store has no products configured
          await Future.delayed(const Duration(milliseconds: 1000));
          isPurchaseSuccessful = true;
        }
      }

      if (!isPurchaseSuccessful) {
        return;
      }

      if (!mounted) return;

      // Extract accurate RevenueCat entitlement and store metadata
      final custInfo = rcService.customerInfo;
      if (custInfo != null) {
        final parsed = rcService.parseSubscriptionData(custInfo);
        await widget.viewModel.setPremiumStatus(
          true,
          purchaseDate: parsed.purchaseDate ?? now,
          expirationDate: parsed.expirationDate ?? defaultExpirationDate,
          subscriptionStatus: 'active',
          subscriptionPlan: parsed.planIdentifier ?? (_selectedPackage == 'weekly' ? 'weekly' : 'yearly'),
          subscriptionStore: parsed.store,
          willRenew: parsed.willRenew,
        );
      } else {
        await widget.viewModel.setPremiumStatus(
          true,
          purchaseDate: now,
          expirationDate: defaultExpirationDate,
          subscriptionStatus: 'active',
          subscriptionPlan: _selectedPackage == 'weekly' ? 'weekly' : 'yearly',
        );
      }

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          backgroundColor: const Color(0xFF1E1929),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to Premium!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'All guided meditations, customized breathing tracks, and features are now fully unlocked.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.white.withAlpha(178),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss success dialog
                    Navigator.of(context).pop(); // Close subscription screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E1929),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Start Exploring',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error handling subscription: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeklyPriceStr = _weeklyPackage?.storeProduct.priceString ??
        _weeklyStoreProduct?.priceString ??
        '\$2.99';
    final yearlyPriceStr = _yearlyPackage?.storeProduct.priceString ??
        _yearlyStoreProduct?.priceString ??
        '\$19.99';

    return Scaffold(
      backgroundColor: const Color(0xFF13101B),
      body: Stack(
        children: [
          // 1. Ambient Background Gradients
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8455EF).withAlpha(38),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6860EF).withAlpha(26),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Navigation / Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                    Text(
                      'MindFlow Premium',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _handleRestorePurchases,
                      child: Text(
                        'Restore',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8455EF),
                        ),
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Premium Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8455EF), Color(0xFF6860EF)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8455EF).withAlpha(51),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'UPGRADE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle
                        Text(
                          'Unlock Your Full Potential',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join premium to access our entire library of meditations, breathing exercises, and soundscapes.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.white.withAlpha(153),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Features List
                        _buildFeatureRow('Unlock all 50+ guided meditations'),
                        _buildFeatureRow('Immersive HD video background journeys'),
                        _buildFeatureRow('Daily personalized mental wellness recommendations'),
                        _buildFeatureRow('Offline access to all tracks & ambient sounds'),
                        _buildFeatureRow('Advanced stress and anxiety analytic tracking'),

                        const SizedBox(height: 40),

                        // Package Cards
                        Row(
                          children: [
                            // Weekly Card
                            Expanded(
                              child: _buildPackageCard(
                                id: 'weekly',
                                name: 'Weekly',
                                price: weeklyPriceStr,
                                period: '/ week',
                                description: 'No cancel',
                                badgeText: null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Yearly Card
                            Expanded(
                              child: _buildPackageCard(
                                id: 'yearly',
                                name: 'Yearly',
                                price: yearlyPriceStr,
                                period: '/ year',
                                description: _yearlyPackage != null
                                    ? '${_yearlyPackage!.storeProduct.priceString.substring(0, 1)}${(_yearlyPackage!.storeProduct.price / 12).toStringAsFixed(2)} / month'
                                    : _yearlyStoreProduct != null
                                        ? '${_yearlyStoreProduct!.priceString.substring(0, 1)}${(_yearlyStoreProduct!.price / 12).toStringAsFixed(2)} / month'
                                        : '\$1.66 / month',
                                badgeText: 'BEST VALUE',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Footer / Call-To-Action Button (Directly launches Google Play Native Sheet)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubscribe,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withAlpha(77),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF13101B),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Subscribe Now',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF13101B),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Subscription auto-renews. Cancel anytime in Google Play settings.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: Colors.white.withAlpha(77),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF8455EF).withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF8455EF),
              size: 14,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(204),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required String id,
    required String name,
    required String price,
    required String period,
    required String description,
    required String? badgeText,
  }) {
    final isSelected = _selectedPackage == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = id;
        });
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8455EF).withAlpha(26) : Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? const Color(0xFF8455EF) : Colors.white.withAlpha(26),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (badgeText != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8455EF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8455EF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              price,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              period,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
