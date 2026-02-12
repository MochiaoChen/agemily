import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/llm_config.dart';
import '../../../providers/settings_providers.dart';

class ModelSelectorButton extends ConsumerWidget {
  const ModelSelectorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(activeModelProvider);

    return GestureDetector(
      onTap: () => _showModelPicker(context, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            model.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  void _showModelPicker(BuildContext context, WidgetRef ref) {
    final currentModel = ref.read(selectedModelProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final model in kAnthropicModels)
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    leading: model.id == currentModel.id
                        ? Icon(Icons.check, color: colorScheme.onSurface)
                        : const SizedBox(width: 24),
                    title: Text(
                      model.name,
                      style: TextStyle(
                        fontWeight: model.id == currentModel.id
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      model.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () {
                      ref.read(selectedModelProvider.notifier).state = model;
                      ref.read(activeModelProvider.notifier).state = model;
                      Navigator.pop(ctx);
                    },
                  ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '复杂问题会自动使用 Opus',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
