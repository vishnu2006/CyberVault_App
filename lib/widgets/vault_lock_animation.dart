import 'package:flutter/material.dart';

class VaultLockAnimation extends StatefulWidget {
  final bool isLocked;
  final VoidCallback? onAnimationComplete;

  const VaultLockAnimation({
    super.key,
    required this.isLocked,
    this.onAnimationComplete,
  });

  @override
  State<VaultLockAnimation> createState() => _VaultLockAnimationState();
}

class _VaultLockAnimationState extends State<VaultLockAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _glowAnimation;
  Color? _primaryColor;
  Color? _errorColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
        
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.3,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.7,
      ),
    ]).animate(_controller);
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 2.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
    
    if (!widget.isLocked) {
      _controller.forward().then((_) {
        widget.onAnimationComplete?.call();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Access theme colors here after dependencies are established
    _primaryColor = Theme.of(context).colorScheme.primary;
    _errorColor = Theme.of(context).colorScheme.error;
    
    // Update color animation if colors are available
    if (_primaryColor != null && _errorColor != null) {
      _colorAnimation = ColorTween(
        begin: _errorColor,
        end: _primaryColor,
      ).chain(CurveTween(curve: Curves.easeInOut))
       .animate(_controller);
    }
  }

  Color _getCurrentColor() {
    if (_colorAnimation != null) {
      return _colorAnimation.value ?? (_primaryColor ?? Colors.green);
    }
    // Fallback when animation is not yet initialized
    return widget.isLocked ? (_errorColor ?? Colors.red) : (_primaryColor ?? Colors.green);
  }

  @override
  void didUpdateWidget(VaultLockAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLocked != widget.isLocked) {
      if (widget.isLocked) {
        _controller.reverse();
      } else {
        _controller.forward().then((_) {
          widget.onAnimationComplete?.call();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentColor = _getCurrentColor();
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  currentColor.withOpacity(0.3),
                  currentColor.withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: currentColor.withOpacity(0.4),
                  blurRadius: 30 * _glowAnimation.value,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Transform.rotate(
              angle: _rotationAnimation.value * 0.1,
              child: Icon(
                widget.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 80,
                color: currentColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
