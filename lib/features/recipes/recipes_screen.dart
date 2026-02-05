import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pantry/pantry_controller.dart';
import 'recipe_models.dart';
import 'recipe_service.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  bool _loading = false;
  String? _error;
  List<RecipeSuggestion> _recipes = const [];

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = ref.read(pantryControllerProvider);
      final recipes = await RecipeService.instance.generateRecipes(
        items: items,
      );

      setState(() => _recipes = recipes);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantryItems = ref.watch(pantryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCard(pantryCount: pantryItems.length),
            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Generating…' : 'Generate recipes'),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.errorContainer,
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            Expanded(
              child: _recipes.isEmpty
                  ? Center(
                      child: Text(
                        pantryItems.isEmpty
                            ? 'Add pantry items first, then generate recipes.'
                            : 'Tap “Generate recipes” to get ideas.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _recipes.length,
                      itemBuilder: (context, index) {
                        final r = _recipes[index];
                        return _RecipeCard(
                          recipe: r,
                          onTap: () => _openRecipe(r),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecipe(RecipeSuggestion r) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${r.cookTimeMinutes} min • ${r.difficulty}'),
                const SizedBox(height: 16),

                const Text(
                  'Uses (from pantry)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: r.uses.map((s) => Chip(label: Text(s))).toList(),
                ),

                const SizedBox(height: 14),
                const Text(
                  'Missing',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: r.missing.map((s) => Chip(label: Text(s))).toList(),
                ),

                const SizedBox(height: 14),
                const Text(
                  'Steps',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  r.steps.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('${i + 1}. ${r.steps[i]}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int pantryCount;
  const _HeroCard({required this.pantryCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cook with what you have',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text('Pantry items available: $pantryCount'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeSuggestion recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.restaurant)),
        title: Text(
          recipe.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('Uses: ${recipe.uses.take(3).join(', ')}'),
        trailing: Text(
          '${recipe.cookTimeMinutes} min',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
