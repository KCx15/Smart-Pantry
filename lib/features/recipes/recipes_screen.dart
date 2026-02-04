import 'package:flutter/material.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCard(),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('15–30 min')),
                Chip(label: Text('Vegetarian')),
                Chip(label: Text('High protein')),
                Chip(label: Text('Use expiring items')),
              ],
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: null, // enable when AI is added
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate recipes (coming soon)'),
            ),
            const SizedBox(height: 16),

            const Text(
              'Suggested ideas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: const [
                  _RecipeCard(
                    title: 'Pasta with tomato & tuna',
                    subtitle: 'Uses: pasta, tomato, tuna',
                    time: '20 min',
                  ),
                  _RecipeCard(
                    title: 'Omelette with leftover veggies',
                    subtitle: 'Uses: eggs, veggies',
                    time: '15 min',
                  ),
                  _RecipeCard(
                    title: 'Rice bowl with beans',
                    subtitle: 'Uses: rice, beans',
                    time: '25 min',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cook with what you have',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Soon you’ll get AI recipes based on your pantry and expiry dates.',
                  ),
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
  final String title;
  final String subtitle;
  final String time;

  const _RecipeCard({
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.restaurant)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
