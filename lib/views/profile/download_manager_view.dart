// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/download_service.dart';

class DownloadManagerView extends StatefulWidget {
  const DownloadManagerView({super.key});

  @override
  State<DownloadManagerView> createState() => _DownloadManagerViewState();
}

class _DownloadManagerViewState extends State<DownloadManagerView> {
  late final DownloadService _downloadService;

  @override
  void initState() {
    super.initState();
    _downloadService = DownloadService();
  }

  @override
  void dispose() {
    _downloadService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _downloadService,
          builder: (context, _) {
            final items = _downloadService.downloadedSessions;

            return Column(
              children: [
                // Custom Navigation Bar
                _buildAppBar(context),

                // Storage Header Card
                _buildStorageHeaderCard(),

                const SizedBox(height: 16),

                // Downloaded Sessions List
                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildDownloadTile(item);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(10),
              elevation: 2,
              shadowColor: Colors.black12,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Offline Downloads',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.assessmentTextPrimary,
                ),
              ),
              Text(
                'Listen offline anywhere without internet',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.assessmentTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageHeaderCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9DEF5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.offline_pin_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Storage Used',
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  color: AppColors.assessmentTextSecondary,
                ),
              ),
              Text(
                _downloadService.formattedTotalStorage,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.assessmentTextPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_downloadService.downloadedSessions.length} Saved',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF27AE60),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadTile(DownloadedItem item) {
    final mb = (item.fileSize / (1024 * 1024)).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9DEF5), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.music_note_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.assessmentTextPrimary,
                  ),
                ),
                Text(
                  '$mb MB • Downloaded',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.assessmentTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _downloadService.deleteDownloadedSession(item.id),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Remove download',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.download_done_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Offline Sessions Yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.assessmentTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloaded sessions will appear here for offline playback.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.assessmentTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
