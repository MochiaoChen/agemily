import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/llm_config.dart';
import '../../core/models/message.dart';
import '../../providers/chat_providers.dart';
import '../../providers/session_providers.dart';
import '../../providers/settings_providers.dart';
import 'widgets/chat_drawer.dart';
import 'widgets/model_selector.dart';

const _user = types.User(id: 'user');
const _assistant = types.User(id: 'assistant', firstName: 'Claude');

/// Max slide distance for the drawer reveal.
const _kDrawerWidth = 300.0;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _imagePicker = ImagePicker();
  List<ImageBlock> _pendingImages = [];
  bool _isProcessingImage = false;
  double _imageProgress = 0.0;

  // Network retry
  StreamSubscription? _connectivitySub;
  _PendingRetry? _pendingRetry;

  // Text-to-speech
  String? _ttsPlayingId;

  // Caches to avoid expensive re-parsing/decoding on every build()
  final Map<String, List<ContentBlock>> _contentCache = {};
  final Map<String, Uint8List> _imageCache = {};

  List<ContentBlock> _parseContent(String id, String json) {
    return _contentCache.putIfAbsent(id, () => ContentBlock.listFromJson(json));
  }

  Uint8List _decodeImage(String key, String base64Data) {
    return _imageCache.putIfAbsent(key, () => base64Decode(base64Data));
  }

  void _clearCaches() {
    _contentCache.clear();
    _imageCache.clear();
  }

  void _onTapLink(String text, String? href, String title) {
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
  }

  void _toggleTts(String messageId, String text) async {
    final tts = TextToSpeechHelper.instance;
    if (_ttsPlayingId == messageId) {
      await tts.stop();
      if (mounted) setState(() => _ttsPlayingId = null);
      return;
    }
    // Strip thinking prefix (💡 ...\n\n) for cleaner speech
    final clean = text.startsWith('\u{1F4A1}') && text.contains('\n\n')
        ? text.substring(text.indexOf('\n\n') + 2)
        : text;
    if (mounted) setState(() => _ttsPlayingId = messageId);
    await tts.speak(clean, onComplete: () {
      if (mounted) setState(() => _ttsPlayingId = null);
    });
  }

  // Sidebar slide animation
  late AnimationController _drawerController;
  bool _drawerOpen = false;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    try {
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final hasConnection =
            results.any((r) => r != ConnectivityResult.none);
        if (hasConnection && _pendingRetry != null) {
          final retry = _pendingRetry!;
          _pendingRetry = null;
          ref.read(chatErrorProvider.notifier).state = null;
          _doSend(retry.text, images: retry.images);
        }
      });
    } catch (_) {
      // connectivity_plus may fail on some devices; non-critical feature
    }
  }

  @override
  void dispose() {
    TextToSpeechHelper.instance.stop();
    _drawerController.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_drawerOpen) {
      _drawerController.reverse().then((_) {
        setState(() => _drawerOpen = false);
      });
    } else {
      setState(() => _drawerOpen = true);
      _drawerController.forward();
    }
  }

  void _closeDrawer() {
    if (_drawerOpen) {
      _drawerController.reverse().then((_) {
        setState(() => _drawerOpen = false);
      });
    }
  }

  Future<void> _createNewChat() async {
    final model = ref.read(selectedModelProvider);
    final id =
        await ref.read(sessionManagerProvider).createSession(model: model);
    ref.read(currentSessionIdProvider.notifier).state = id;
  }

  Future<void> _ensureSession() async {
    final sessionId = ref.read(currentSessionIdProvider);
    if (sessionId == null) {
      await _createNewChat();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _isProcessingImage = true;
        _imageProgress = 0.0;
      });

      // Simulate progress for file reading
      setState(() => _imageProgress = 0.3);
      final bytes = await File(picked.path).readAsBytes();

      setState(() => _imageProgress = 0.7);
      final base64 = base64Encode(bytes);
      final mimeType =
          picked.path.endsWith('.png') ? 'image/png' : 'image/jpeg';

      setState(() => _imageProgress = 1.0);

      // Brief delay to show completion
      await Future.delayed(const Duration(milliseconds: 200));

      setState(() {
        _pendingImages.add(ImageBlock(data: base64, mimeType: mimeType));
        _isProcessingImage = false;
        _imageProgress = 0.0;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
          _imageProgress = 0.0;
        });
      }
    }
  }

  void _showAttachmentSheet() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('添加到对话',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(
                    icon: Icons.camera_alt_outlined,
                    label: '拍照',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _AttachOption(
                    icon: Icons.photo_library_outlined,
                    label: '相册',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSend(types.PartialText partial) async {
    final text = partial.text.trim();
    if (text.isEmpty && _pendingImages.isEmpty) return;

    await _ensureSession();

    final images = _pendingImages.isNotEmpty ? List<ImageBlock>.from(_pendingImages) : null;
    setState(() => _pendingImages = []);

    await _doSend(text.isEmpty ? '请看这张图片' : text, images: images);
  }

  Future<void> _doSend(String text, {List<ImageBlock>? images}) async {
    // Check connectivity first (may throw on some iOS devices)
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasConnection =
          connectivity.any((r) => r != ConnectivityResult.none);

      if (!hasConnection) {
        _pendingRetry = _PendingRetry(text: text, images: images);
        ref.read(chatErrorProvider.notifier).state = '网络不可用，连接恢复后将自动重试';
        return;
      }
    } catch (_) {
      // connectivity_plus may fail on some devices; proceed with send
    }

    ref.read(sendMessageProvider).call(
      text,
      images: images,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = ref.watch(currentSessionIdProvider);
    final isStreaming = ref.watch(isStreamingProvider);
    final streamingText = ref.watch(streamingTextProvider);
    final streamingThinking = ref.watch(streamingThinkingProvider);
    final isSearching = ref.watch(isSearchingProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final error = ref.watch(chatErrorProvider);
    final hasKey = ref.watch(hasApiKeyProvider);
    final activeModel = ref.watch(activeModelProvider);

    // Build chat messages list
    final chatMessages = <types.Message>[];

    // Add streaming message if active
    if (isStreaming) {
      if (streamingText.isEmpty) {
        // Show animated loading indicator via custom message
        chatMessages.add(types.CustomMessage(
          author: _assistant,
          id: 'streaming',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          metadata: {
            'type': 'loading',
            'thinking': streamingThinking.isNotEmpty,
            'searching': isSearching,
            'searchQuery': searchQuery,
          },
        ));
      } else {
        chatMessages.add(types.TextMessage(
          author: _assistant,
          id: 'streaming',
          text: streamingText,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    }

    // Convert DB messages
    if (sessionId != null) {
      final messagesAsync = ref.watch(messagesProvider(sessionId));
      messagesAsync.whenData((msgs) {
        for (int i = msgs.length - 1; i >= 0; i--) {
          final row = msgs[i];
          final isUser = row.role == 'user';
          final author = isUser ? _user : _assistant;
          final content = _parseContent(row.id, row.content);
          final text = content
              .whereType<TextBlock>()
              .map((b) => b.text)
              .join();
          final hasImages = content.any((b) => b is ImageBlock);

          if (hasImages && isUser) {
            // For image messages, show as custom message with pre-decoded bytes
            final imageBlock =
                content.whereType<ImageBlock>().first;
            chatMessages.add(types.CustomMessage(
              author: author,
              id: '${row.id}_img',
              createdAt: row.createdAt.millisecondsSinceEpoch,
              metadata: {
                'type': 'image',
                'msgId': row.id,
                'base64': imageBlock.data,
                'mimeType': imageBlock.mimeType,
              },
            ));
            if (text.isNotEmpty && text != '请看这张图片') {
              chatMessages.add(types.TextMessage(
                author: author,
                id: row.id,
                text: text,
                createdAt: row.createdAt.millisecondsSinceEpoch,
              ));
            }
          } else {
            // Check for thinking blocks in assistant messages
            final thinkingBlocks = content.whereType<ThinkingBlock>().toList();
            final displayText = thinkingBlocks.isNotEmpty
                ? '💡 ${_truncate(thinkingBlocks.first.thinking, 40)}\n\n$text'
                : text;
            if (displayText.isNotEmpty) {
              chatMessages.add(types.TextMessage(
                author: author,
                id: row.id,
                text: displayText,
                createdAt: row.createdAt.millisecondsSinceEpoch,
                metadata: {
                  if (!isUser && row.model != null) 'model': row.model,
                },
              ));
            }
          }
        }
      });
    }

    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth < _kDrawerWidth + 60
        ? screenWidth * 0.8
        : _kDrawerWidth;

    // Main content widget
    final mainContent = Column(
      children: [
        // Top bar
        _TopBar(
          activeModel: activeModel,
          onMenuTap: _toggleDrawer,
          onNewChat: () {
            ref.read(currentSessionIdProvider.notifier).state = null;
            ref.read(streamingTextProvider.notifier).state = '';
            ref.read(streamingThinkingProvider.notifier).state = '';
            ref.read(isSearchingProvider.notifier).state = false;
            ref.read(searchQueryProvider.notifier).state = '';
            ref.read(chatErrorProvider.notifier).state = null;
            _pendingRetry = null;
            _clearCaches();
            setState(() => _pendingImages = []);
          },
        ),
        // Error bar
        if (error != null)
          _ErrorBar(
            error: error,
            isRetrying: _pendingRetry != null,
          ),
        // Image processing indicator
        if (_isProcessingImage)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: _imageProgress > 0 ? _imageProgress : null,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '处理图片中...',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _imageProgress > 0 ? _imageProgress : null,
                    minHeight: 2,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        // Chat area
        Expanded(
          child: chatMessages.isEmpty && !isStreaming
              ? _EmptyState()
              : Chat(
                  messages: chatMessages,
                  onSendPressed: _handleSend,
                  user: _user,
                  showUserAvatars: false,
                  showUserNames: false,
                  customStatusBuilder: (_, {required context}) =>
                      const SizedBox.shrink(),
                  messageWidthRatio: 1.0,
                  l10n: const ChatL10nZhCN(
                    inputPlaceholder: '输入消息...',
                  ),
                  customBottomWidget: const SizedBox.shrink(),
                  customMessageBuilder: (msg, {required int messageWidth}) {
                    final meta = msg.metadata;
                    if (meta == null) return const SizedBox.shrink();
                    final type = meta['type'] as String?;
                    if (type == 'image') {
                      final cacheKey = (meta['msgId'] as String?) ?? msg.id;
                      final bytes = _decodeImage(cacheKey, meta['base64'] as String);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          bytes,
                          width: messageWidth * 0.7,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    if (type == 'loading') {
                      final isThinking = meta['thinking'] == true;
                      final isSearching = meta['searching'] == true;
                      final searchQuery = meta['searchQuery'] as String? ?? '';
                      return _LoadingIndicator(
                        isThinking: isThinking,
                        isSearching: isSearching,
                        searchQuery: searchQuery,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  textMessageBuilder: (msg, {required messageWidth, required showName}) {
                    final isAssistant = msg.author.id != 'user';
                    final isStreaming = msg.id == 'streaming';

                    if (!isAssistant) {
                      // User message — standard sans-serif on dark bubble
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(msg.text, style: TextStyle(
                          color: colorScheme.surface,
                          fontSize: 17,
                          height: 1.5,
                          fontFamily: 'serif',
                        )),
                      );
                    }

                    // Assistant message — serif font, markdown rendered
                    final mdStyle = MarkdownStyleSheet(
                      p: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 17,
                        height: 1.7,
                        fontFamily: 'serif',
                        letterSpacing: 0.1,
                      ),
                      h1: TextStyle(color: colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'serif'),
                      h2: TextStyle(color: colorScheme.onSurface, fontSize: 19, fontWeight: FontWeight.w600, fontFamily: 'serif'),
                      h3: TextStyle(color: colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'serif'),
                      code: TextStyle(
                        color: colorScheme.onSurface,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      listBullet: TextStyle(color: colorScheme.onSurface, fontFamily: 'serif'),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(left: BorderSide(color: colorScheme.outline, width: 3)),
                      ),
                      blockquotePadding: const EdgeInsets.only(left: 12),
                    );

                    if (isStreaming) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: MarkdownBody(
                              data: msg.text,
                              styleSheet: mdStyle,
                              selectable: false,
                              shrinkWrap: true,
                              onTapLink: _onTapLink,
                            ),
                          ),
                          if (isSearching)
                            _LoadingIndicator(
                              isSearching: true,
                              searchQuery: searchQuery,
                            ),
                        ],
                      );
                    }

                    // Completed assistant message with action bar
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: MarkdownBody(
                            data: msg.text,
                            styleSheet: mdStyle,
                            selectable: true,
                            shrinkWrap: true,
                            onTapLink: _onTapLink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final clean = msg.text.startsWith('\u{1F4A1}') && msg.text.contains('\n\n')
                                    ? msg.text.substring(msg.text.indexOf('\n\n') + 2)
                                    : msg.text;
                                Clipboard.setData(ClipboardData(text: clean));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('已复制'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.copy_outlined,
                                size: 16,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => _toggleTts(msg.id, msg.text),
                              child: Icon(
                                _ttsPlayingId == msg.id
                                    ? Icons.stop_circle_outlined
                                    : Icons.volume_up_outlined,
                                size: 16,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  bubbleBuilder: (child, {required message, required nextMessageInGroup}) {
                    if (message.author.id == 'user') {
                      return Container(
                        margin: const EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: child,
                      );
                    }
                    // Assistant: no bubble, just 20px horizontal padding
                    return Padding(
                      padding: const EdgeInsets.only(left: 20, right: 40),
                      child: child,
                    );
                  },
                  theme: DefaultChatTheme(
                    backgroundColor:
                        Theme.of(context).scaffoldBackgroundColor,
                    primaryColor: colorScheme.onSurface,
                    secondaryColor: Colors.transparent,
                    sentMessageBodyTextStyle: TextStyle(
                      color: colorScheme.surface,
                      fontSize: 17,
                      height: 1.5,
                      fontFamily: 'serif',
                    ),
                    receivedMessageBodyTextStyle: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 17,
                      height: 1.5,
                      fontFamily: 'serif',
                    ),
                    messageBorderRadius: 18,
                    messageInsetsHorizontal: 16,
                    messageInsetsVertical: 10,
                    bubbleMargin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
        ),
        // Input bar
        _ChatInputBar(
          images: _pendingImages,
          enabled: !isStreaming && hasKey && !_isProcessingImage,
          onSend: (text) async =>
              await _handleSend(types.PartialText(text: text)),
          onAttachmentTap: _showAttachmentSheet,
          onRemoveImage: (i) =>
              setState(() => _pendingImages.removeAt(i)),
        ),
      ],
    );

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          final delta = details.primaryDelta ?? 0;
          final newValue = _drawerController.value + delta / drawerWidth;
          _drawerController.value = newValue.clamp(0.0, 1.0);
        },
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 300) {
            // Fast swipe right → open
            setState(() => _drawerOpen = true);
            _drawerController.forward();
          } else if (velocity < -300) {
            // Fast swipe left → close
            _drawerController.reverse().then((_) {
              setState(() => _drawerOpen = false);
            });
          } else if (_drawerController.value > 0.5) {
            setState(() => _drawerOpen = true);
            _drawerController.forward();
          } else {
            _drawerController.reverse().then((_) {
              setState(() => _drawerOpen = false);
            });
          }
        },
        child: AnimatedBuilder(
          animation: _drawerController,
          builder: (context, child) {
            final slideAmount = _drawerController.value * drawerWidth;
            return Stack(
              children: [
                // Below layer: sidebar (fixed, revealed by main sliding)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: drawerWidth,
                  child: ChatDrawer(onClose: _closeDrawer),
                ),
                // Main content layer (slides right)
                Transform.translate(
                  offset: Offset(slideAmount, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: slideAmount > 0
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(-4, 0),
                              ),
                            ]
                          : null,
                      borderRadius: slideAmount > 0
                          ? BorderRadius.circular(16)
                          : null,
                    ),
                    clipBehavior: slideAmount > 0
                        ? Clip.antiAlias
                        : Clip.none,
                    child: SafeArea(
                      bottom: false,
                      child: mainContent,
                    ),
                  ),
                ),
                // Tap-to-close overlay when drawer is open
                if (_drawerController.value > 0)
                  Positioned(
                    left: slideAmount,
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: _drawerController.value > 0.3
                        ? GestureDetector(
                            onTap: _closeDrawer,
                            behavior: HitTestBehavior.opaque,
                            child: Container(color: Colors.transparent),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}...' : s;
}

class _PendingRetry {
  final String text;
  final List<ImageBlock>? images;
  _PendingRetry({required this.text, this.images});
}

class _TopBar extends StatelessWidget {
  final LlmModel activeModel;
  final VoidCallback onMenuTap;
  final VoidCallback onNewChat;
  const _TopBar({
    required this.activeModel,
    required this.onMenuTap,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenuTap,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(Icons.menu, size: 22, color: colorScheme.onSurface),
            ),
          ),
          const Expanded(child: Center(child: ModelSelectorButton())),
          GestureDetector(
            onTap: onNewChat,
            child: Container(
              height: 32,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('\u2728',
              style: TextStyle(
                  fontSize: 32,
                  color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 16),
          Text(
            '有什么可以帮你的？',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBar extends ConsumerWidget {
  final String error;
  final bool isRetrying;
  const _ErrorBar({required this.error, this.isRetrying = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (isRetrying)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.error,
              ),
            )
          else
            Icon(Icons.error_outline, color: colorScheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error,
                style:
                    TextStyle(color: colorScheme.onErrorContainer, fontSize: 13)),
          ),
          GestureDetector(
            onTap: () {
              ref.read(chatErrorProvider.notifier).state = null;
            },
            child: Icon(Icons.close, size: 16, color: colorScheme.error),
          ),
        ],
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Custom input bar with inline image previews and send button.
class _ChatInputBar extends StatefulWidget {
  final List<ImageBlock> images;
  final bool enabled;
  final ValueChanged<String> onSend;
  final VoidCallback onAttachmentTap;
  final ValueChanged<int> onRemoveImage;

  const _ChatInputBar({
    required this.images,
    required this.enabled,
    required this.onSend,
    required this.onAttachmentTap,
    required this.onRemoveImage,
  });

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateHasContent);
  }

  void _updateHasContent() {
    final has = _controller.text.trim().isNotEmpty || widget.images.isNotEmpty;
    if (has != _hasContent) setState(() => _hasContent = has);
  }

  @override
  void didUpdateWidget(_ChatInputBar old) {
    super.didUpdateWidget(old);
    if (old.images.length != widget.images.length) {
      _updateHasContent();
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty && widget.images.isEmpty) return;
    widget.onSend(text.isEmpty ? '请看这张图片' : text);
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
    final hasImages = widget.images.isNotEmpty;
    final canSend = _hasContent || hasImages;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(hasImages ? 16 : 24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image thumbnails row
                if (hasImages)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.images.length,
                        itemBuilder: (context, index) {
                          final img = widget.images[index];
                          final bytes = base64Decode(img.data);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: MemoryImage(bytes),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: () => widget.onRemoveImage(index),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                // Text field
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  style:
                      TextStyle(fontSize: 16, color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: '发消息...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    filled: false,
                  ),
                ),
                // Bottom row: + button, mic button, and send button
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      // Attachment button
                      GestureDetector(
                        onTap: widget.enabled ? widget.onAttachmentTap : null,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest,
                          ),
                          child: Icon(Icons.add,
                              size: 18,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const Spacer(),
                      // Send button
                      GestureDetector(
                        onTap: widget.enabled && canSend ? _send : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: canSend
                                ? colorScheme.onSurface
                                : colorScheme.surfaceContainerHighest,
                          ),
                          child: Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: canSend
                                ? colorScheme.surface
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
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

/// Animated loading indicator for streaming messages.
class _LoadingIndicator extends StatefulWidget {
  final bool isThinking;
  final bool isSearching;
  final String searchQuery;
  const _LoadingIndicator({
    this.isThinking = false,
    this.isSearching = false,
    this.searchQuery = '',
  });

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
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

    // Determine which status label to show (searching takes priority).
    IconData? statusIcon;
    String? statusLabel;
    if (widget.isSearching) {
      statusIcon = Icons.travel_explore;
      statusLabel = widget.searchQuery.isNotEmpty
          ? '搜索「${_truncateQuery(widget.searchQuery)}」'
          : '搜索中';
    } else if (widget.isThinking) {
      statusIcon = Icons.lightbulb_outline;
      statusLabel = '思考中';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusIcon != null) ...[
            Icon(statusIcon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                statusLabel!,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 6),
          ],
          ...List.generate(3, (i) {
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
                    color:
                        colorScheme.onSurfaceVariant.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  static String _truncateQuery(String q) =>
      q.length > 20 ? '${q.substring(0, 18)}…' : q;
}

/// Singleton helper wrapping flutter_tts plugin.
class TextToSpeechHelper {
  TextToSpeechHelper._();
  static final instance = TextToSpeechHelper._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  VoidCallback? _onComplete;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(Platform.isIOS ? 0.5 : 0.45);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() {
        final cb = _onComplete;
        _onComplete = null;
        cb?.call();
      });
      _tts.setCancelHandler(() {
        final cb = _onComplete;
        _onComplete = null;
        cb?.call();
      });
    } catch (_) {
      // TTS may be unavailable on some devices
    }
    _initialized = true;
  }

  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    try {
      await _ensureInit();
      // Auto-detect language: >10% Chinese chars → zh-CN
      final zhCount = RegExp(r'[\u4e00-\u9fff]').allMatches(text).length;
      await _tts.setLanguage(zhCount > text.length * 0.1 ? 'zh-CN' : 'en-US');
      _onComplete = onComplete;
      await _tts.speak(text);
    } catch (_) {
      _onComplete = null;
      onComplete?.call();
    }
  }

  Future<void> stop() async {
    _onComplete = null;
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore — TTS may not be available
    }
  }
}
