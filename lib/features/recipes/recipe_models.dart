class RecipeSuggestion {
  final String title;
  final int cookTimeMinutes;
  final String difficulty; // "easy" | "medium" | "hard"
  final List<String> uses;
  final List<String> missing;
  final List<String> steps;

  const RecipeSuggestion({
    required this.title,
    required this.cookTimeMinutes,
    required this.difficulty,
    required this.uses,
    required this.missing,
    required this.steps,
  });

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) {
    return RecipeSuggestion(
      title: (json['title'] ?? '') as String,
      cookTimeMinutes: (json['cook_time_minutes'] ?? 0) as int,
      difficulty: (json['difficulty'] ?? 'easy') as String,
      uses: List<String>.from(json['uses'] ?? const []),
      missing: List<String>.from(json['missing'] ?? const []),
      steps: List<String>.from(json['steps'] ?? const []),
    );
  }
}
