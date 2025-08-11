import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 2)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorHex;

  @HiveField(3)
  int? iconCodePoint;

  Category({
    required this.id,
    required this.name,
    required this.colorHex,
    this.iconCodePoint,
  });
}
