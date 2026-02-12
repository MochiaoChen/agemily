import 'dart:convert';

enum MessageRole { user, assistant, system }

sealed class ContentBlock {
  Map<String, dynamic> toJson();

  static ContentBlock fromJson(Map<String, dynamic> json) {
    return switch (json['type']) {
      'text' => TextBlock(text: json['text'] as String),
      'thinking' => ThinkingBlock(
          thinking: json['thinking'] as String,
          signature: json['signature'] as String?,
        ),
      'image' => ImageBlock(
          data: json['data'] as String,
          mimeType: json['mimeType'] as String,
        ),
      'audio' => AudioBlock(
          data: json['data'] as String,
          mimeType: json['mimeType'] as String,
        ),
      _ => TextBlock(text: json['text'] as String? ?? ''),
    };
  }

  static List<ContentBlock> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list
        .map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<ContentBlock> blocks) {
    return jsonEncode(blocks.map((b) => b.toJson()).toList());
  }
}

class TextBlock extends ContentBlock {
  final String text;
  TextBlock({required this.text});

  @override
  Map<String, dynamic> toJson() => {'type': 'text', 'text': text};
}

class ThinkingBlock extends ContentBlock {
  final String thinking;
  final String? signature;
  ThinkingBlock({required this.thinking, this.signature});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'thinking',
    'thinking': thinking,
    if (signature != null) 'signature': signature,
  };
}

class ImageBlock extends ContentBlock {
  final String data;
  final String mimeType;
  ImageBlock({required this.data, required this.mimeType});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    'data': data,
    'mimeType': mimeType,
  };
}

class AudioBlock extends ContentBlock {
  final String data;
  final String mimeType;
  AudioBlock({required this.data, required this.mimeType});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'audio',
    'data': data,
    'mimeType': mimeType,
  };
}

class Message {
  final String id;
  final String sessionId;
  final String? parentId;
  final MessageRole role;
  final List<ContentBlock> content;
  final String? model;
  final int? inputTokens;
  final int? outputTokens;
  final String? stopReason;
  final bool isCompactionSummary;
  final DateTime createdAt;
  final int sortOrder;

  Message({
    required this.id,
    required this.sessionId,
    this.parentId,
    required this.role,
    required this.content,
    this.model,
    this.inputTokens,
    this.outputTokens,
    this.stopReason,
    this.isCompactionSummary = false,
    required this.createdAt,
    required this.sortOrder,
  });

  String get textContent {
    return content
        .whereType<TextBlock>()
        .map((b) => b.text)
        .join();
  }

  List<ThinkingBlock> get thinkingBlocks {
    return content.whereType<ThinkingBlock>().toList();
  }

  Message copyWith({
    List<ContentBlock>? content,
    String? model,
    int? inputTokens,
    int? outputTokens,
    String? stopReason,
  }) {
    return Message(
      id: id,
      sessionId: sessionId,
      parentId: parentId,
      role: role,
      content: content ?? this.content,
      model: model ?? this.model,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      stopReason: stopReason ?? this.stopReason,
      isCompactionSummary: isCompactionSummary,
      createdAt: createdAt,
      sortOrder: sortOrder,
    );
  }
}
