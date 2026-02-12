class TokenCounter {
  static const double _charsPerToken = 4.0;

  /// Heuristic estimate: ~4 characters per token
  static int estimate(String text) {
    return (text.length / _charsPerToken).ceil();
  }

  /// Estimate tokens for a list of messages
  static int estimateMessages(List<String> texts) {
    return texts.fold(0, (sum, text) => sum + estimate(text));
  }
}
