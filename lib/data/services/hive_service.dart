import 'package:hive/hive.dart';
import 'package:notes_app/data/models/note.dart';
import 'package:notes_app/data/models/category.dart';
import 'package:uuid/uuid.dart';

class HiveService {
  static const categoriesBoxName = 'categoriesBox';
  static const notesBoxName = 'notesBox';

  static Future<void> init() async {
    // Open boxes only if not already open
    if (!Hive.isBoxOpen(notesBoxName)) {
      await Hive.openBox<Note>(notesBoxName);
    }
    if (!Hive.isBoxOpen(categoriesBoxName)) {
      final categories = await Hive.openBox<Category>(categoriesBoxName);

      // Seed default categories if empty
      if (categories.isEmpty) {
        final uuid = const Uuid();
        categories.addAll([
          Category(
            id: uuid.v4(),
            name: 'Work',
            colorHex: 0xFF1565C0,
            iconCodePoint: 0xe0af,
          ),
          Category(
            id: uuid.v4(),
            name: 'Personal',
            colorHex: 0xFF2E7D32,
            iconCodePoint: 0xe7fd,
          ),
          Category(
            id: uuid.v4(),
            name: 'Ideas',
            colorHex: 0xFFF9A825,
            iconCodePoint: 0xe3af,
          ),
        ]);
      }
    }
  }

  static Box<Note> get notesBox => Hive.box<Note>(notesBoxName);
  static Box<Category> get categoriesBox =>
      Hive.box<Category>(categoriesBoxName);
}
