class RecipeSuggestion {
  final String title;
  final int cookTimeMinutes;
  final String difficulty;
  final List<String> uses;
  final List<String> missing;
  final int missingCount;

  final List<String> expiringItemsUsed;
  final int matchScore;

  final List<String> steps;

  const RecipeSuggestion({
    required this.title,
    required this.cookTimeMinutes,
    required this.difficulty,
    required this.uses,
    required this.missing,
    required this.missingCount,
    required this.expiringItemsUsed,
    required this.matchScore,
    required this.steps,
  });

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    return RecipeSuggestion(
      title: (json['title'] ?? '') as String,
      cookTimeMinutes: asInt(json['cook_time_minutes']),
      difficulty: (json['difficulty'] ?? 'easy') as String,
      uses: List<String>.from(json['uses'] ?? const []),
      missing: List<String>.from(json['missing'] ?? const []),
      missingCount: asInt(json['missing_count']),
      expiringItemsUsed: List<String>.from(
        json['expiring_items_used'] ?? const [],
      ),
      matchScore: asInt(json['match_score']),
      steps: List<String>.from(json['steps'] ?? const []),
    );
  }
}
