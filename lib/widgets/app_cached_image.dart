import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../services/image_cache_service.dart';
import '../services/service_locator.dart';

/// Professional Cached Image widget with Shimmer loading skeleton.
/// Checks local disk/SharedPreferences first for 0ms instant loading.
/// If not downloaded yet, fetches image once, saves it locally, and displays it.
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorPlaceholder();
    }

    // 1. Instant check: Check SharedPreferences & local disk cache (0ms load time)
    File? cachedFile;
    try {
      if (locator.isRegistered<ImageCacheService>()) {
        cachedFile = locator<ImageCacheService>().getLocalCachedImage(imageUrl);
      }
    } catch (_) {}

    Widget imageWidget;

    if (cachedFile != null) {
      imageWidget = Image.file(
        cachedFile,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: 600,
        errorBuilder: (context, error, stackTrace) =>
            _buildDownloadFallback(context),
      );
    } else {
      imageWidget = _buildDownloadFallback(context);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDownloadFallback(BuildContext context) {
    if (!locator.isRegistered<ImageCacheService>()) {
      return _buildNetworkDirectImage();
    }

    return FutureBuilder<File?>(
      future: locator<ImageCacheService>().getOrDownloadImage(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          return Image.file(
            snapshot.data!,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: 600,
            errorBuilder: (context, error, stackTrace) =>
                _buildNetworkDirectImage(),
          );
        }

        if (snapshot.hasError) {
          return _buildNetworkDirectImage();
        }

        // Display smooth shimmer skeleton while downloading to local disk
        return AppShimmer(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          borderRadius: borderRadius,
        );
      },
    );
  }

  Widget _buildNetworkDirectImage() {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: 600,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return AppShimmer(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          borderRadius: borderRadius,
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ?? _buildErrorPlaceholder(),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(
          Icons.spa_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }
}

/// Standalone Shimmer Skeleton widget for smooth loading UI.
class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        ),
      ),
    );
  }
}
