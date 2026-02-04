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
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Cook with what you have',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Soon you’ll get AI recipe suggestions based on your pantry items, '
                      'expiry dates, and preferences.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: null, // enabled later (AI)
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate recipes (coming soon)'),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: const [
                  _RecipePlaceholderCard(title: 'Pasta with tomato & tuna'),
                  _RecipePlaceholderCard(
                    title: 'Omelette with leftover veggies',
                  ),
                  _RecipePlaceholderCard(title: 'Rice bowl with beans'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipePlaceholderCard extends StatelessWidget {
  final String title;
  const _RecipePlaceholderCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.restaurant)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('AI suggestion placeholder'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
