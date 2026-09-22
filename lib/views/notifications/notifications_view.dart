import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../profile/notification_settings_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {

  IconData _getIcon(String iconType) {
    switch (iconType) {
      case 'spa':
        return Icons.spa_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'moon':
        return Icons.nightlight_round;
      case 'shield':
        return Icons.shield_rounded;
      case 'goal':
        return Icons.track_changes_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String iconType) {
    switch (iconType) {
      case 'spa':
        return const Color(0xFF6B38D4);
      case 'fire':
        return const Color(0xFFFF9800);
      case 'moon':
        return const Color(0xFF2E0052);
      case 'shield':
        return const Color(0xFF27AE60);
      case 'goal':
        return const Color(0xFF8455EF);
      default:
        return AppColors.primary;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
      return '${mins}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationsViewModel>();
    final filtered = viewModel.filteredNotifications;

    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Navigation Bar
            _buildAppBar(context, viewModel),

            // Category Filter Chips
            _buildCategoryFilterRow(context, viewModel),

            const SizedBox(height: 12),

            // Notification List / Loading Indicator
            Expanded(
              child: viewModel.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildNotificationCard(context, viewModel, item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, NotificationsViewModel viewModel) {
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
              Row(
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                  if (viewModel.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${viewModel.unreadCount}',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                'Live mindful updates & personal reminders',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.assessmentTextSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Settings Button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsView(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(10),
              elevation: 2,
              shadowColor: Colors.black12,
            ),
            tooltip: 'Notification Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterRow(BuildContext context, NotificationsViewModel viewModel) {
    final categories = ['All', 'Mindfulness', 'Reminder', 'System'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = viewModel.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: GoogleFonts.manrope(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.assessmentTextPrimary,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          viewModel.setCategory(cat);
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE9DEF5),
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (viewModel.unreadCount > 0)
            TextButton(
              onPressed: () {
                viewModel.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'All notifications marked as read',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Read all',
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationsViewModel viewModel, DynamicNotificationItem item) {
    final iconData = _getIcon(item.iconType);
    final iconColor = _getIconColor(item.iconType);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => viewModel.removeNotification(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700),
      ),
      child: GestureDetector(
        onTap: () {
          viewModel.markAsRead(item.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isRead
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE9DEF5)
                  : AppColors.primary.withValues(alpha: 0.3),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Message Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: AppColors.assessmentTextPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _formatTimestamp(item.timestamp),
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        color: AppColors.assessmentTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
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
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All Caught Up!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.assessmentTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no notifications in this category right now.',
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
