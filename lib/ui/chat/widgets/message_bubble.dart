import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    if (isUser) {
      return _UserMessage(text: message.textContent);
    }
    return _AssistantMessage(message: message);
  }
}

class _UserMessage extends StatelessWidget {
  final String text;
  const _UserMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  final Message message;
  const _AssistantMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thinking blocks (collapsible)
          if (message.thinkingBlocks.isNotEmpty)
            _ThinkingChip(blocks: message.thinkingBlocks),
          // Main content - flat markdown
          MarkdownBody(
            data: message.textContent,
            selectable: true,
            onTapLink: (text, href, title) {
              if (href == null) return;
              final uri = Uri.tryParse(href);
              if (uri == null) return;
              if (uri.scheme != 'https' && uri.scheme != 'http') return;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('打开链接'),
                  content: Text('确定要打开以下链接吗？\n\n$href'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: const Text('打开'),
                    ),
                  ],
                ),
              );
            },
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                height: 1.6,
              ),
              h1: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              h2: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              h3: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              strong: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              listBullet: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
              ),
              code: TextStyle(
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.onSurface,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              codeblockDecoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: colorScheme.outline,
                    width: 3,
                  ),
                ),
              ),
              blockquotePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingChip extends StatefulWidget {
  final List<ThinkingBlock> blocks;
  const _ThinkingChip({required this.blocks});

  @override
  State<_ThinkingChip> createState() => _ThinkingChipState();
}

class _ThinkingChipState extends State<_ThinkingChip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = widget.blocks.map((b) => b.thinking).join('\n');
    final preview =
        text.length > 50 ? '${text.substring(0, 47)}...' : text;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collapsed chip
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _expanded ? '思考过程' : preview,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.chevron_right,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            // Expanded content
            if (_expanded)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Streaming message widget (not yet persisted).
class StreamingMessage extends StatelessWidget {
  final String text;
  final String thinking;

  const StreamingMessage({
    super.key,
    required this.text,
    required this.thinking,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thinking.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '思考中...',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          if (text.isNotEmpty)
            MarkdownBody(
              data: text,
              selectable: true,
              onTapLink: (linkText, href, title) {
                if (href == null) return;
                final uri = Uri.tryParse(href);
                if (uri == null) return;
                if (uri.scheme != 'https' && uri.scheme != 'http') return;
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('打开链接'),
                    content: Text('确定要打开以下链接吗？\n\n$href'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        child: const Text('打开'),
                      ),
                    ],
                  ),
                );
              },
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.6,
                ),
                strong: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                code: TextStyle(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            _TypingIndicator(),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = (_controller.value + i * 0.2) % 1.0;
            final opacity =
                (1.0 - (offset - 0.5).abs() * 2).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
