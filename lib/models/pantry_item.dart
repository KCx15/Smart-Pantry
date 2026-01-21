import 'package:hive/hive.dart';

part 'pantry_item.g.dart';

@HiveType(typeId: 0)
class PantryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final DateTime expiryDate;

  @HiveField(4)
  final String? imagePath;

  @HiveField(5)
  final DateTime createdAt;

  PantryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.expiryDate,
    required this.createdAt,
    this.imagePath,
  });

  PantryItem copyWith({
    String? id,
    String? name,
    int? quantity,
    DateTime? expiryDate,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
