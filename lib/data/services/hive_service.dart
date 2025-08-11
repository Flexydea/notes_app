import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notes_app/data/models/note.dart';
import 'package:uuid/uuid.dart';
import 'package:notes_app/data/models/category.dart';
import 'package:uuid/uuid.dart';

class HiveService {
  static const categoriesBoxName = 'categoriesBox';
  static const notesBoxName = 'notesBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    // These adapters must be registered in main.dart BEFORE calling init()
    // Hive.registerAdapter(NoteAdapter());
    // Hive.registerAdapter(CategoryAdapter());

    //Open boxes
    // await Hive.openBox(notesBoxName);
    // await Hive.openBox(categoriesBoxName);

    if (Hive.isBoxOpen(notesBoxName)) {
      await Hive.box(notesBoxName).close();
    }
    if (Hive.isBoxOpen(categoriesBoxName)) {
      await Hive.box(categoriesBoxName).close();
    }
    // --- Seed default categories here ---

    await Hive.openBox<Note>(notesBoxName);
    final categories = await Hive.openBox<Category>(categoriesBoxName);
    if (categories.isEmpty) {
      final uuid = const Uuid();
      categories.addAll([
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

  static Box get notesBox => Hive.box<Note>(notesBoxName);
  static Box get categoriesBox => Hive.box<Category>(categoriesBoxName);
}
