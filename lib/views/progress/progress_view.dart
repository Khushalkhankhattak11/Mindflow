import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/progress_model.dart';
import '../../viewmodels/progress_viewmodel.dart';
import 'progress_analytics_view.dart';

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProgressViewModel>();
    final stats = viewModel.data;
    final primaryColor = AppColors.primary;
    final secondaryTextColor = AppColors.assessmentTextSecondary;

    return Scaffold(
      body: Stack(
            children: [
              // Ambient backgrounds
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF4EAFF),
                        Color(0xFFFEF7FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Header navigation
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(204),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4B0082).withAlpha(10),
                        blurRadius: 30,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon:  Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                             Icon(
                              Icons.spa,
                              color: primaryColor,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MindFlow',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProgressAnalyticsView(),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.bar_chart_rounded,
                                color: primaryColor,
                              ),
                              tooltip: 'Mindfulness Analytics',
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor.withAlpha(51),
                                  width: 2,
                                ),
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCu4skK1Xjs2ufhbBLYErwJEwMzjkv03LFFQJW2RB3WLhAsW3A6YCeAWA6BKIP1T0VYfUQZoBzl6wMU6iveMOjtxwBaOIgZnJeFDXXYJg66FxopjeJ4u5j6WY3OeSWKItsLbfvKSZeR3__rZ69fIsu4Pc6RPjEIfaiWBrObdJ5OMruhURmo0poMMl9jiGEE5eXA-MS2lbeoqAyNm9uHIEd4G2NznSiAxvzg-doZTi_a_lLQmofikzL6CA',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Scrollable progress data
              Positioned.fill(
                top: 90,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Goal Circular Progress Hero
                          _buildCircularProgressHero(stats, primaryColor, secondaryTextColor),
                          const SizedBox(height: 32),

                          // 2. Stats Bento Cards Grid
                          LayoutBuilder(
                            builder: (context, gridConstraints) {
                              final cols = gridConstraints.maxWidth > 560 ? 3 : 1;

                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: cols,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: cols == 3 ? 1.05 : 2.5,
                                children: [
                                  _buildStatCard(
                                    icon: Icons.timer_outlined,
                                    color: primaryColor,
                                    count: stats.totalMeditationMinutes.toString(),
                                    label: 'Meditation Minutes',
                                  ),
                                  _buildStatCard(
                                    icon: Icons.local_fire_department,
                                    color: Colors.deepOrange,
                                    count: '${stats.streakDays} Days',
                                    label: 'Current Streak',
                                  ),
                                  _buildStatCard(
                                    icon: Icons.task_alt,
                                    color: AppColors.homeSecondary,
                                    count: stats.completedSessions.toString(),
                                    label: 'Sessions Completed',
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 32),

                          // 3. Weekly Progress Line Chart Card
                          _buildWeeklyProgressCard(stats, primaryColor, secondaryTextColor),
                          const SizedBox(height: 32),

                          // 4. Milestones Section
                          _buildMilestonesHeader(primaryColor),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, milestonesConstraints) {
                              final cols = milestonesConstraints.maxWidth > 560 ? 2 : 1;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: stats.milestones.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: cols == 2 ? 2.1 : 3.0,
                                ),
                                itemBuilder: (context, index) {
                                  final milestone = stats.milestones[index];
                                  return _buildMilestoneCard(milestone, primaryColor);
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  // Circular progress sweep hero
  Widget _buildCircularProgressHero(ProgressData stats, Color primaryColor, Color secondaryTextColor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background blur glow
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withAlpha(20),
              ),
            ),
            // Custom paint circular sweep ring
            SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: ProgressRingPainter(
                  progress: stats.dailyGoalPercentage,
                  strokeWidth: 14,
                ),
              ),
            ),
            // Inner labels
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6B38D4), Color(0xFF8455EF)],
                  ).createShader(bounds),
                  child: Text(
                    '${(stats.dailyGoalPercentage * 100).toInt()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  'DAILY GOAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: secondaryTextColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Almost there, Alex!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.assessmentTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "You've completed ${stats.completedMinutes} minutes of your ${stats.goalMinutes}-minute daily meditation goal.",
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Custom interactive stats card
  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String count,
    required String label,
  }) {
    return _StatHoverCard(
      icon: icon,
      color: color,
      count: count,
      label: label,
    );
  }

  // Weekly progress line chart
  Widget _buildWeeklyProgressCard(ProgressData stats, Color primaryColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(153), // glass-card
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withAlpha(77), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B0082).withAlpha(5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Progress',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.assessmentTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Time spent in mindfulness (Min)',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'This Week',
                  style: GoogleFonts.plusJakartaSans(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Custom Bezier line chart painter
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: BezierChartPainter(
                data: stats.weeklyMinutes,
                maxVal: 60,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Weekly labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DayLabel(label: 'Mon'),
              _DayLabel(label: 'Tue'),
              _DayLabel(label: 'Wed'),
              _DayLabel(label: 'Thu', isActive: true),
              _DayLabel(label: 'Fri'),
              _DayLabel(label: 'Sat'),
              _DayLabel(label: 'Sun'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesHeader(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Milestones',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.assessmentTextPrimary,
          ),
        ),
      ],
    );
  }

  // Bento Milestone Badge Card
  Widget _buildMilestoneCard(MilestoneItem item, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(153),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(77), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(item.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.assessmentTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.assessmentTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Milestone progress or unlocked pill
                if (item.isUnlocked)
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Achievement Unlocked',
                        style: GoogleFonts.manrope(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 5,
                      width: double.infinity,
                      color: const Color(0xFFE9DEF5),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: item.progress,
                        child: Container(
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Hover/touch stats card implementation
class _StatHoverCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String count;
  final String label;

  const _StatHoverCard({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  State<_StatHoverCard> createState() => _StatHoverCardState();
}

class _StatHoverCardState extends State<_StatHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        transform: Matrix4.diagonal3Values(_isHovered ? 1.02 : 1.0, _isHovered ? 1.02 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(153),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(77), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(_isHovered ? 10 : 3),
              blurRadius: _isHovered ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isHovered ? widget.color : widget.color.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.icon,
                color: _isHovered ? Colors.white : widget.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.count,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.assessmentTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppColors.assessmentTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Daily label indicator
class _DayLabel extends StatelessWidget {
  final String label;
  final bool isActive;

  const _DayLabel({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.primary : AppColors.welcomeOutline,
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Circular Gradient Sweep Progress Ring
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  ProgressRingPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track circle
    final trackPaint = Paint()
      ..color = const Color(0xFFE9DEF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Sweep arc paint with linear gradient
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF6B38D4), Color(0xFFD0BCFF)],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + 1;

    // Draw arc rotated starting at -90 degrees
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter for Bezier Curve Line Chart
class BezierChartPainter extends CustomPainter {
  final List<double> data;
  final double maxVal;

  BezierChartPainter({required this.data, required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final stepX = width / (data.length - 1);

    // Compute point coordinates
    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      // Invert Y axis
      final y = height - (data[i] / maxVal) * height;
      points.add(Offset(x, y));
    }

    // Draw smooth Bezier curve line path
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      // Control points for cubic bezier curves
      final controlX1 = p0.dx + stepX / 2;
      final controlY1 = p0.dy;
      final controlX2 = p1.dx - stepX / 2;
      final controlY2 = p1.dy;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    // Chart path paint with linear gradient
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6B38D4), Color(0xFFD0BCFF)],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    canvas.drawPath(path, linePaint);

    // Draw data point dots
    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = AppColors.primary.withAlpha(51)
      ..style = PaintingStyle.fill;

    for (final pt in points) {
      canvas.drawCircle(pt, 8, ringPaint); // Outer ring glow
      canvas.drawCircle(pt, 4, dotPaint); // Inner solid dot
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
