import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

import '../../models/pantry_item.dart';
import 'recipe_models.dart';

class RecipeService {
  RecipeService._();
  static final RecipeService instance = RecipeService._();

  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<List<RecipeSuggestion>> generateRecipes({
    required List<PantryItem> items,
    int maxRecipes = 5,
    String diet = 'any',
    List<String> allergies = const [],
    int maxTimeMinutes = 30,
  }) async {
    final payload = {
      'max_recipes': maxRecipes,
      'diet': diet,
      'allergies': allergies,
      'max_time_minutes': maxTimeMinutes,
      'pantry': items
          .map(
            (i) => {
              'name': i.name,
              'quantity': i.quantity,
              'expiry_iso': i.expiryDate.toIso8601String(),
            },
          )
          .toList(),
    };

    final callable = _functions.httpsCallable('generateRecipes');
    final result = await callable.call(payload);

    // ✅ Normalize Firebase Callable response types:
    // Map<Object?, Object?> -> Map<String, dynamic>
    final normalized = jsonDecode(jsonEncode(result.data));

    final data = Map<String, dynamic>.from(normalized as Map);

    final recipesRaw = (data['recipes'] as List?) ?? const [];
    final recipesList = recipesRaw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return recipesList.map(RecipeSuggestion.fromJson).toList();
  }
}
