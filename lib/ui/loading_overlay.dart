import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {

  final bool isLoading;
  final Widget child;
  final double opacity;
  final Color color;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.opacity = 0.5,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) Positioned.fill(
          child: AbsorbPointer(
            absorbing: true, // blocks touch/click events
            child: MouseRegion(
              cursor: SystemMouseCursors.wait, // shows busy cursor on web
              child: Container(
                color: color.withValues(alpha: opacity), // TODO: check it
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}