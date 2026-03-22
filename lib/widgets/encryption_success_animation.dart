import 'package:flutter/material.dart';

/// Animation shown after file is encrypted and uploaded.
class EncryptionSuccessAnimation extends StatefulWidget {
  final String fileName;
  final VoidCallback onComplete;

  const EncryptionSuccessAnimation({
    super.key,
    required this.fileName,
    required this.onComplete,
  });

  @override
  State<EncryptionSuccessAnimation> createState() =>
      _EncryptionSuccessAnimationState();
}

class _EncryptionSuccessAnimationState extends State<EncryptionSuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _lockController;
  late AnimationController _shieldController;
  late Animation<double> _lockScale;
  late Animation<double> _shieldOpacity;

  @override
  void initState() {
    super.initState();
    _lockController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shieldController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _lockScale = Tween<double>(begin: 0.5, end: 1.2)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_lockController);

    _shieldOpacity = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_shieldController);

    _lockController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _shieldController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _lockController.dispose();
    _shieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _lockController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _shieldOpacity,
                      child: ScaleTransition(
                        scale: _lockScale,
                        child: Icon(
                          Icons.lock,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Encrypted & Secured',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 4,
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
