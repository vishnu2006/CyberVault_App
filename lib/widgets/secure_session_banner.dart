import 'package:flutter/material.dart';

class SecureSessionBanner extends StatefulWidget {
  const SecureSessionBanner({super.key});

  @override
  State<SecureSessionBanner> createState() => _SecureSessionBannerState();
}

class _SecureSessionBannerState extends State<SecureSessionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;
  Color? _primaryColor;
  Color? _secondaryColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
        ));
        
    _controller.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Access theme colors here after dependencies are established
    _primaryColor = Theme.of(context).colorScheme.primary;
    _secondaryColor = Theme.of(context).colorScheme.secondary;
    
    // Update color animation if colors are available
    if (_primaryColor != null && _secondaryColor != null) {
      _colorAnimation = ColorTween(
        begin: _primaryColor,
        end: _secondaryColor,
      ).chain(CurveTween(curve: Curves.easeInOut))
       .animate(CurvedAnimation(
         parent: _controller,
         curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
       ));
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
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (_primaryColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
                (_secondaryColor ?? Theme.of(context).colorScheme.secondary).withOpacity(0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: _colorAnimation.value ?? (_primaryColor ?? Theme.of(context).colorScheme.primary),
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _primaryColor ?? Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_primaryColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF0F172A),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '🔒 Secure Session Active',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _primaryColor ?? Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _colorAnimation.value ?? (_primaryColor ?? Theme.of(context).colorScheme.primary),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_colorAnimation.value ?? (_primaryColor ?? Theme.of(context).colorScheme.primary)).withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
