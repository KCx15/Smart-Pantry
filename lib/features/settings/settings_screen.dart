import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _ThemeChoiceTile(
                    label: 'System',
                    value: ThemeMode.system,
                    group: mode,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).setMode(v),
                  ),
                  _ThemeChoiceTile(
                    label: 'Light',
                    value: ThemeMode.light,
                    group: mode,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).setMode(v),
                  ),
                  _ThemeChoiceTile(
                    label: 'Dark',
                    value: ThemeMode.dark,
                    group: mode,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).setMode(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notification preferences'),
              subtitle: Text('Reminder timing, quiet hours (coming soon)'),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const ListTile(
              leading: Icon(Icons.tune),
              title: Text('Recipe preferences'),
              subtitle: Text('Diet, allergies, servings (coming soon)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeChoiceTile extends StatelessWidget {
  final String label;
  final ThemeMode value;
  final ThemeMode group;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeChoiceTile({
    required this.label,
    required this.value,
    required this.group,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      groupValue: group,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
