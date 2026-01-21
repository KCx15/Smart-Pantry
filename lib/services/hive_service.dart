import 'package:hive_flutter/hive_flutter.dart';
import '../models/pantry_item.dart';

class HiveService {
  static const String pantryBoxName = 'pantry_items';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(PantryItemAdapter());
    await Hive.openBox<PantryItem>(pantryBoxName);
  }

  static Box<PantryItem> pantryBox() => Hive.box<PantryItem>(pantryBoxName);
}
