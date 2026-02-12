import 'package:flutter/material.dart';

class StreamingIndicator extends StatefulWidget {
  const StreamingIndicator({super.key});

  @override
  State<StreamingIndicator> createState() => _StreamingIndicatorState();
}

class _StreamingIndicatorState extends State<StreamingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = (_controller.value + i * 0.2) % 1.0;
              final opacity = (1.0 - (offset - 0.5).abs() * 2).clamp(0.3, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
