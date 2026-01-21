import 'package:flutter/material.dart';

class PantryListScreen extends StatelessWidget {
  const PantryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Pantry')),
      body: const Center(child: Text('Pantry items will appear here')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Next step: navigate to Add/Edit screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
