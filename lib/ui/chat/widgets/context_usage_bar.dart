import 'package:flutter/material.dart';

class ContextUsageBar extends StatelessWidget {
  final int currentTokens;
  final int contextWindow;
  final int compactionCount;

  const ContextUsageBar({
    super.key,
    required this.currentTokens,
    required this.contextWindow,
    this.compactionCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = contextWindow > 0 ? currentTokens / contextWindow : 0.0;
    final color = ratio < 0.5
        ? Colors.green
        : ratio < 0.8
            ? Colors.orange
            : Colors.red;

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('上下文使用', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('当前 tokens: $currentTokens / $contextWindow'),
            const SizedBox(height: 4),
            Text('使用率: ${(currentTokens / contextWindow * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 4),
            Text('压缩次数: $compactionCount'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
