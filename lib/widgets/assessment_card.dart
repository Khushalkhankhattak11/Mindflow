import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AssessmentCard extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;

  const AssessmentCard({
    super.key,
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<AssessmentCard> createState() => _AssessmentCardState();
}

class _AssessmentCardState extends State<AssessmentCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapCancel: () => _controller.reverse(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? primaryColor.withAlpha(26) // rgba(107, 56, 212, 0.1)
                : Colors.white.withAlpha(115), // rgba(255, 255, 255, 0.45)
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected ? primaryColor : Colors.white.withAlpha(128),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withAlpha(widget.isSelected ? 38 : 10),
                blurRadius: widget.isSelected ? 40 : 32,
                offset: Offset(0, widget.isSelected ? 12 : 8),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
