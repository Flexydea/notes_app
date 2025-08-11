import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:notes_app/data/models/category.dart';
import 'package:uuid/uuid.dart';

class HiveService {
  static const noteBoxName = 'notesBox';
  static const categoryBoxName = 'categoriesBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    // These adapters must be registered in main.dart BEFORE calling init()
    // Hive.registerAdapter(NoteAdapter());
    // Hive.registerAdapter(CategoryAdapter());

    //Open boxes
    await Hive.openBox(noteBoxName);
    await Hive.openBox(categoryBoxName);

    // --- Seed default categories here ---

    final box = Hive.box<Category>(categoryBoxName);
    if (box.isEmpty) {
      final uuid = const Uuid();
      box.addAll([
        Category(
          id: uuid.v4(),
          name: 'Work',
          colorHex: 0xFF1565C0, // blue
          iconCodePoint: 0xe0af, // work icon
        ),
        Category(
          id: uuid.v4(),
          name: 'Personal',
          colorHex: 0xFF2E7D32, // green
          iconCodePoint: 0xe7fd, // person icon
        ),
        Category(
          id: uuid.v4(),
          name: 'Ideas',
          colorHex: 0xFFF9A825, // yellow
          iconCodePoint: 0xe3af, // lightbulb icon
        ),
      ]);
    }
  }

  static Box get notesBox => Hive.box(noteBoxName);
  static Box get categoriesBox => Hive.box(categoryBoxName);
}
