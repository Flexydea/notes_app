// lib/features/categories/views/category_tasks_screen.dart
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
  bool _selectionMode = false;
  final Set<int> _selectedKeys = {}; //Hive keys of selected category

  String _filter = 'all';
  String _query = '';
  String _sort = 'newest'; // newest | oldest | favFirst

  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController(); // NEW

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesBox = HiveService.notesBox;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          if (_selectionMode) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('${_selectedKeys.length} selected'),
              ),
            ),
            IconButton(
              tooltip: 'Delete Selected',
              icon: const Icon(Icons.delete),
              onPressed: _selectedKeys.isEmpty
                  ? null
                  : () async {
                      final ok = await _confirmDelete(context);
                      if (ok == true) {
                        final box = HiveService.notesBox;
                        for (final k in _selectedKeys) {
                          await box.delete(k);
                        }
                        setState(() {
                          _selectedKeys.clear();
                          _selectionMode = false;
                        });
                      }
                    },
            ),
            IconButton(
              tooltip: 'Exit selection',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _selectionMode = false;
                _selectedKeys.clear();
              }),
            ),
          ] else ...[
            IconButton(
              icon: Icon(_showSearch ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _query = '';
                    _searchCtrl.clear();
                  }
                });
              },
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'deleteCategory') {
                  final ok = await _confirmDelete(context);
                  if (ok == true) {
                    // Delete notes in this category, then the category itself
                    final notes = HiveService.notesBox;
                    final cats = HiveService.categoriesBox;
                    final idsToDelete = notes.values
                        .where((n) => n.categoryId == widget.category.id)
                        .map((n) => n.key as int)
                        .toList();
                    for (final k in idsToDelete) {
                      await notes.delete(k);
                    }
                    // remove category (by index)
                    final catKey = widget.category.key as int;
                    await cats.delete(catKey);
                    if (mounted)
                      Navigator.pop(context); // back to Categories list
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'deleteCategory',
                  child: Text('Delete category'),
                ),
              ],
            ),
          ],
        ],
        bottom: _showSearch
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search notes…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    onChanged: (val) =>
                        setState(() => _query = val), // LIVE FILTER
                    onSubmitted: (val) => setState(() => _query = val),
                  ),
                ),
              )
            : null,
      ),
      body: ValueListenableBuilder(
        valueListenable: notesBox.listenable(),
        builder: (context, Box<Note> box, _) {
          // 1) load + category-filter
          final allInCat = box.values
              .where((n) => n.categoryId == widget.category.id)
              .toList();

          // 2) apply view filter
          final showFavOnly = _filter == 'fav';
          var visible = showFavOnly
              ? allInCat.where((n) => (n.isFavorite ?? false)).toList()
              : allInCat;

          // 3) search filter (title or body, case-insensitive)
          final q = _query.trim().toLowerCase();
          if (q.isNotEmpty) {
            visible = visible.where((n) {
              final t = n.title.toLowerCase();
              final b = n.body.toLowerCase();
              return t.contains(q) || b.contains(q);
            }).toList();
          }

          // Pins always float to top, then apply chosen sort within groups
          int _cmpDate(Note a, Note b) => b.updatedAt.compareTo(a.updatedAt);
          int _cmpDateAsc(Note a, Note b) => a.updatedAt.compareTo(b.updatedAt);

          visible.sort((a, b) {
            final ap = (a.isPinned ?? false);
            final bp = (b.isPinned ?? false);
            if (ap != bp) return bp ? 1 : -1; // pinned first

            if (_sort == 'newest') return _cmpDate(a, b);
            if (_sort == 'oldest') return _cmpDateAsc(a, b);

            // favFirst as a third mode (optional)
            if (_sort == 'favFirst') {
              final af = (a.isFavorite ?? false);
              final bf = (b.isFavorite ?? false);
              if (af != bf) return bf ? 1 : -1; // favorites next
              return _cmpDate(a, b);
            }

            return 0;
          });
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
                        : (_query.isNotEmpty
                              ? 'No results for "$_query"'
                              : 'No items in this category'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  if (_query.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _query = ''),
                      child: const Text('Clear search'),
                    )
                  else
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
                    if (_query.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          label: Text('“$_query”'),
                          onDeleted: () => setState(() => _query = ''),
                        ),
                      ),
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
                    const SizedBox(width: 12),

                    // Sort menu (Newest / Oldest / Favorites first)
                    PopupMenuButton<String>(
                      initialValue: _sort,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'newest',
                          child: Text('Sort: Newest first'),
                        ),
                        PopupMenuItem(
                          value: 'oldest',
                          child: Text('Sort: Oldest first'),
                        ),
                        PopupMenuItem(
                          value: 'favFirst',
                          child: Text('Sort: Favorites first'),
                        ),
                      ],
                      onSelected: (v) => setState(() => _sort = v),
                      child: Row(
                        children: [
                          Text(
                            _sort == 'newest'
                                ? 'Newest'
                                : _sort == 'oldest'
                                ? 'Oldest'
                                : 'Fav first',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.sort),
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
                    final key = note.key as int;
                    final isSelected = _selectedKeys.contains(key);

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
                        if (_selectionMode)
                          return false; // disable swipe while selecting
                        if (direction == DismissDirection.startToEnd) {
                          // Toggle favorite
                          final current = notesBox.get(key);
                          if (current != null) {
                            await notesBox.put(
                              key,
                              current.copyWith(
                                isFavorite: !(current.isFavorite ?? false),
                                updatedAt: DateTime.now(),
                              ),
                            );
                          }
                          return false;
                        } else {
                          final ok = await _confirmDelete(context);
                          if (ok == true) {
                            await notesBox.delete(key);
                            return true;
                          }
                          return false;
                        }
                      },
                      child: InkWell(
                        onLongPress: () {
                          setState(() {
                            _selectionMode = true;
                            _selectedKeys.add(key);
                          });
                        },
                        onTap: () {
                          if (_selectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedKeys.remove(key);
                                if (_selectedKeys.isEmpty)
                                  _selectionMode = false;
                              } else {
                                _selectedKeys.add(key);
                              }
                            });
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NoteEditorScreen(
                                  noteKey: key,
                                  categoryId: widget.category.id,
                                ),
                              ),
                            );
                          }
                        },
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(isSelected ? 0.7 : 0.4),
                          leading: _selectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedKeys.add(key);
                                      } else {
                                        _selectedKeys.remove(key);
                                        if (_selectedKeys.isEmpty)
                                          _selectionMode = false;
                                      }
                                    });
                                  },
                                )
                              : Icon(
                                  (note.isFavorite ?? false)
                                      ? Icons.star
                                      : Icons.note_outlined,
                                ),
                          title: Text(
                            note.title.isEmpty ? '(Untitled)' : note.title,
                          ),
                          subtitle: Text(_subtitleWithUpdated(note)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'pin') {
                                final cur = notesBox.get(key);
                                if (cur != null) {
                                  await notesBox.put(
                                    key,
                                    cur.copyWith(
                                      isPinned: !(cur.isPinned ?? false),
                                      updatedAt: DateTime.now(),
                                    ),
                                  );
                                }
                              } else if (v == 'fav') {
                                final cur = notesBox.get(key);
                                if (cur != null) {
                                  await notesBox.put(
                                    key,
                                    cur.copyWith(
                                      isFavorite: !(cur.isFavorite ?? false),
                                      updatedAt: DateTime.now(),
                                    ),
                                  );
                                }
                              } else if (v == 'delete') {
                                final ok = await _confirmDelete(context);
                                if (ok == true) await notesBox.delete(key);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'pin',
                                child: Text(
                                  (note.isPinned ?? false) ? 'Unpin' : 'Pin',
                                ),
                              ),
                              PopupMenuItem(
                                value: 'fav',
                                child: Text(
                                  (note.isFavorite ?? false)
                                      ? 'Unfavorite'
                                      : 'Favorite',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            child: Icon(
                              (note.isPinned ?? false)
                                  ? Icons.push_pin
                                  : Icons.more_vert,
                            ),
                          ),
                        ),
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
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  NoteEditorScreen(categoryId: widget.category.id), // new note
            ),
          );
        },
        label: const Text('Add Note'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  String _fmt2(int n) => n.toString().padLeft(2, '0');

  String _subtitleWithUpdated(Note n) {
    final updated = n.updatedAt; // DateTime from your model
    final date =
        '${updated.year}-${_fmt2(updated.month)}-${_fmt2(updated.day)} ${_fmt2(updated.hour)}:${_fmt2(updated.minute)}';
    final bodyPreview = n.body.isEmpty
        ? ''
        : (n.body.length > 60 ? '${n.body.substring(0, 60)}…' : n.body);
    // Show “Last updated: … • preview”
    return 'Last updated: $date${bodyPreview.isNotEmpty ? ' • $bodyPreview' : ''}';
  }
}

//////////////// helpers ////////////////

// swipe right background - "Favorite"
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

// swipe left background - "Delete"
Widget _deleteBg(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.9),
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
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

// confirm delete with lottie
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
            child: const Text('Cancel'),
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

/// Compact search delegate used by the AppBar search icon
class _NoteSearchDelegate extends SearchDelegate<String?> {
  _NoteSearchDelegate({String initialQuery = ''}) {
    query = initialQuery;
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => close(context, query),
        child: Text('Search “$query”'),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search notes…'));
    }
    return ListTile(
      leading: const Icon(Icons.search),
      title: Text(query),
      onTap: () => close(context, query),
    );
  }
}
