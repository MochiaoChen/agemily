class Session {
  final String id;
  final String sessionKey;
  final String? title;
  final String model;
  final String provider;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final int contextTokens;
  final int compactionCount;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;

  Session({
    required this.id,
    required this.sessionKey,
    this.title,
    required this.model,
    required this.provider,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.totalTokens = 0,
    this.contextTokens = 0,
    this.compactionCount = 0,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
  });

  Session copyWith({
    String? title,
    String? model,
    String? provider,
    int? inputTokens,
    int? outputTokens,
    int? totalTokens,
    int? contextTokens,
    int? compactionCount,
    bool? isArchived,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
  }) {
    return Session(
      id: id,
      sessionKey: sessionKey,
      title: title ?? this.title,
      model: model ?? this.model,
      provider: provider ?? this.provider,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      contextTokens: contextTokens ?? this.contextTokens,
      compactionCount: compactionCount ?? this.compactionCount,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}
