import 'dart:convert';

class MemoryNote {
  final String id;
  final String title;
  final String content;
  final String? sourceSessionId;
  final List<String> tags;
  final int hitCount;
  final DateTime? lastHitAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemoryNote({
    required this.id,
    required this.title,
    required this.content,
    this.sourceSessionId,
    this.tags = const [],
    this.hitCount = 0,
    this.lastHitAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Score = hitCount * 2 + recencyBonus
  /// where recencyBonus = max(0, 14 - daysSinceLastHit)
  double get score {
    final hitScore = hitCount * 2.0;
    if (lastHitAt == null) return hitScore;
    final daysSince = DateTime.now().difference(lastHitAt!).inDays;
    final recencyBonus = (14 - daysSince).clamp(0, 14).toDouble();
    return hitScore + recencyBonus;
  }

  /// Parse mixed tags JSON: ["auto", {"hitCount": 3, "lastHitAt": "..."}]
  /// Returns (tags, hitCount, lastHitAt).
  static ({List<String> tags, int hitCount, DateTime? lastHitAt}) decodeTags(
      String tagsJson) {
    try {
      final list = jsonDecode(tagsJson) as List;
      final tags = <String>[];
      int hitCount = 0;
      DateTime? lastHitAt;

      for (final item in list) {
        if (item is String) {
          tags.add(item);
        } else if (item is Map) {
          hitCount = (item['hitCount'] as num?)?.toInt() ?? 0;
          final raw = item['lastHitAt'];
          if (raw is String) {
            lastHitAt = DateTime.tryParse(raw);
          }
        }
      }

      return (tags: tags, hitCount: hitCount, lastHitAt: lastHitAt);
    } catch (_) {
      return (tags: <String>[], hitCount: 0, lastHitAt: null);
    }
  }

  /// Serialize tags + hit metadata back to JSON.
  static String encodeTags(List<String> tags, int hitCount,
      [DateTime? lastHitAt]) {
    final list = <dynamic>[...tags];
    if (hitCount > 0 || lastHitAt != null) {
      final meta = <String, dynamic>{'hitCount': hitCount};
      if (lastHitAt != null) {
        meta['lastHitAt'] = lastHitAt.toIso8601String();
      }
      list.add(meta);
    }
    return jsonEncode(list);
  }

  MemoryNote copyWith({
    String? title,
    String? content,
    List<String>? tags,
    int? hitCount,
    DateTime? lastHitAt,
    DateTime? updatedAt,
  }) {
    return MemoryNote(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      sourceSessionId: sourceSessionId,
      tags: tags ?? this.tags,
      hitCount: hitCount ?? this.hitCount,
      lastHitAt: lastHitAt ?? this.lastHitAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
