import 'package:flutter/material.dart';

class ScalePressedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BoxDecoration? decoration;
  final double paddingVertical;
  final double width;

  const ScalePressedButton({
    super.key,
    required this.child,
    required this.onTap,
    this.decoration,
    this.paddingVertical = 16,
    this.width = double.infinity,
  });

  @override
  State<ScalePressedButton> createState() => _ScalePressedButtonState();
}

class _ScalePressedButtonState extends State<ScalePressedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          padding: EdgeInsets.symmetric(vertical: widget.paddingVertical),
          decoration: widget.decoration,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
