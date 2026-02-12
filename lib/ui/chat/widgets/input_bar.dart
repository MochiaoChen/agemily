import 'package:flutter/material.dart';

class InputBar extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSend;
  final VoidCallback? onAttachmentTap;

  const InputBar({
    super.key,
    required this.enabled,
    required this.onSend,
    this.onAttachmentTap,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                // Text field
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    filled: false,
                  ),
                ),
                // Action buttons row
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      // Attachment button
                      _ActionButton(
                        icon: Icons.add,
                        onTap: widget.onAttachmentTap,
                      ),
                      const Spacer(),
                      // Send button
                      _SendButton(
                        hasText: _hasText,
                        enabled: widget.enabled && _hasText,
                        onTap: _send,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surfaceContainerHighest,
        ),
        child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool hasText;
  final bool enabled;
  final VoidCallback onTap;

  const _SendButton({
    required this.hasText,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasText ? colorScheme.onSurface : colorScheme.surfaceContainerHighest,
        ),
        child: Icon(
          Icons.arrow_upward,
          size: 18,
          color: hasText ? colorScheme.surface : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
