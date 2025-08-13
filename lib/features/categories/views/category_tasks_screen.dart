import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';

import 'package:notes_app/data/models/category.dart';
import 'package:notes_app/data/models/note.dart';
import 'package:notes_app/data/services/hive_service.dart';
import 'package:notes_app/features/notes/views/note_editor_screen.dart';

class CategoryTasksScreen extends StatefulWidget {
  final Category category;
  const CategoryTasksScreen({super.key, required this.category});

  @override
  State<CategoryTasksScreen> createState() => _CategoryTasksScreenState();
}

class _CategoryTasksScreenState extends State<CategoryTasksScreen> {
  // all | fav
  String _filter = 'all'; // default view
  String _query = ''; //seach text

  @override
  Widget build(BuildContext context) {
    final notesBox = HiveService.notesBox;

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: ValueListenableBuilder(
        valueListenable: notesBox.listenable(),
        builder: (context, Box<Note> box, _) {
          // 1) load + category-filter
          final allInCat = box.values
              .where((n) => n.categoryId == widget.category.id)
              .toList();

          // 2) apply view filter
          final showFavOnly = _filter == 'fav';
          final visible = showFavOnly
              ? allInCat.where((n) => (n.isFavorite ?? false)).toList()
              : allInCat;

          // counts
          final favCount = allInCat
              .where((n) => (n.isFavorite ?? false))
              .length;
          final total = allInCat.length;

          if (visible.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset('assets/animations/empty.json', width: 220),
                  const SizedBox(height: 12),
                  Text(
                    showFavOnly
                        ? 'No favorites yet'
                        : 'No items in this category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text('Tap + to create one'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '$favCount of $total favorited',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      initialValue: _filter,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'all', child: Text('Show: All')),
                        PopupMenuItem(
                          value: 'fav',
                          child: Text('Show: Favorites'),
                        ),
                      ],
                      onSelected: (v) => setState(() => _filter = v),
                      child: Row(
                        children: [
                          Text(
                            _filter == 'all' ? 'All' : 'Favorites',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.filter_list),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final note = visible[index];
                    final key = note.key;

                    final preview = note.body.isEmpty
                        ? '—'
                        : (note.body.length > 80
                              ? '${note.body.substring(0, 80)}…'
                              : note.body);

                    return Dismissible(
                      key: ValueKey('note-$key'),
                      background: _favBg(context),
                      secondaryBackground: _deleteBg(context),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // Toggle favorite
                          final current = notesBox.get(key);
                          if (current != null) {
                            await notesBox.put(
                              key,
                              current.copyWith(
                                isFavorite: !(current.isFavorite ?? false),
                              ),
                            );
                          }
                          // Keep tile (no remove)
                          return false;
                        } else {
                          final ok = await _confirmDelete(context);
                          if (ok == true) {
                            await notesBox.delete(key);
                            // Remove tile (true)
                            return true;
                          }
                          return false;
                        }
                      },
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.4),
                        title: Text(
                          note.title.isEmpty ? '(Untitled)' : note.title,
                        ),
                        subtitle: Text(preview),
                        trailing: (note.isFavorite ?? false)
                            ? const Icon(Icons.star)
                            : const Icon(Icons.chevron_right),
                        onTap: () {
                          final int noteKey = note.key as int;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteEditorScreen(
                                noteKey: noteKey as int,
                                categoryId: widget.category.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(categoryId: widget.category.id),
            ),
          );
        },
        label: const Text('Add'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // helpers (same as before) ...
}
//////////////helpers block /////////////////

//swip right backgorund - "Faourite"
Widget _favBg(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.amber.withOpacity(0.9),
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    alignment: Alignment.centerLeft,
    child: const Row(
      children: [
        Icon(Icons.star, color: Colors.white),
        SizedBox(width: 8),
        Text('Favorite', style: TextStyle(color: Colors.white)),
      ],
    ),
  );
}

//swipe ;eft backgoround - 'delete'
Widget _deleteBg(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.amber.withOpacity(0.9),
      borderRadius: BorderRadius.circular(16),
    ),
    padding: EdgeInsets.symmetric(horizontal: 16),
    alignment: Alignment.centerRight,
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Delete', style: TextStyle(color: Colors.white)),
        SizedBox(width: 8),
        Icon(Icons.delete_forever, color: Colors.white),
      ],
    ),
  );
}

//confirm delee with lottie
Future<bool?> _confirmDelete(BuildContext context) async {
  bool confirmed = false;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/delete.json',
              width: 180,
              repeat: false,
            ),
            const SizedBox(height: 8),
            const Text('Delete this item?'),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              confirmed = false;
              Navigator.pop(context);
            },
            child: const Text('cancel'),
          ),
          FilledButton(
            onPressed: () {
              confirmed = true;
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  return confirmed;
}
