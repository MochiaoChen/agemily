class TokenUsage {
  final int inputTokens;
  final int outputTokens;
  final int cacheReadTokens;
  final int cacheWriteTokens;

  const TokenUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cacheReadTokens = 0,
    this.cacheWriteTokens = 0,
  });

  int get totalTokens => inputTokens + outputTokens;

  TokenUsage copyWith({
    int? inputTokens,
    int? outputTokens,
    int? cacheReadTokens,
    int? cacheWriteTokens,
  }) {
    return TokenUsage(
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      cacheReadTokens: cacheReadTokens ?? this.cacheReadTokens,
      cacheWriteTokens: cacheWriteTokens ?? this.cacheWriteTokens,
    );
  }
}
