import 'package:flutter/material.dart';

class NeonGlowButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? glowColor;
  final double borderRadius;
  final double glowIntensity;
  final EdgeInsetsGeometry? padding;
  final bool enabled;

  const NeonGlowButton({
    super.key,
    required this.child,
    this.onPressed,
    this.glowColor,
    this.borderRadius = 25,
    this.glowIntensity = 20,
    this.padding,
    this.enabled = true,
  });

  @override
  State<NeonGlowButton> createState() => _NeonGlowButtonState();
}

class _NeonGlowButtonState extends State<NeonGlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
        
    _glowAnimation = Tween<double>(begin: 1.0, end: 1.5)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      _controller.reverse();
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                color: widget.enabled 
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.surface.withOpacity(0.5),
                boxShadow: widget.enabled ? [
                  BoxShadow(
                    color: glowColor.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: widget.glowIntensity * _glowAnimation.value,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: glowColor.withOpacity(0.2),
                    blurRadius: widget.glowIntensity,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: widget.enabled 
                      ? glowColor.withOpacity(0.5)
                      : glowColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: widget.enabled 
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                child: widget.child ?? const SizedBox(),
              ),
            ),
          );
        },
      ),
    );
  }
}
