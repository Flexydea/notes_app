// lib/features/notes/views/note_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:notes_app/data/models/note.dart';
import 'package:notes_app/data/services/hive_service.dart';

class NoteEditorScreen extends StatefulWidget {
  // When null → we are creating a new note
  // When non-null → we are editing the existing Hive record at this key
  final int? noteKey;

  // Always keep category context (used on create; preserved on edit)
  final String categoryId;

  const NoteEditorScreen({
    super.key,
    this.noteKey, // <-- matches the field name
    required this.categoryId,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  Note? _existing; // non-null when editing

  @override
  void initState() {
    super.initState();

    // If we got a key, load the existing note and prefill fields
    if (widget.noteKey != null) {
      final box = HiveService.notesBox; // Box<Note>
      _existing = box.get(widget.noteKey);
      if (_existing != null) {
        _title.text = _existing!.title;
        _body.text = _existing!.body;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote, // Save handler
            tooltip: 'Save',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title input
            TextField(
              controller: _title,
              decoration: const InputDecoration(hintText: 'Title'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            // Body input
            Expanded(
              child: TextField(
                controller: _body,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(hintText: 'Start typing...'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    final title = _title.text.trim();
    final body = _body.text.trim();

    // Avoid saving empty note
    if (title.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Write something first')));
      return;
    }

    final Box<Note> box = HiveService.notesBox;

    if (_existing != null && widget.noteKey != null) {
      // EDIT: update existing note (keep its current category unless you want to move it)
      final updated = _existing!.copyWith(
        title: title,
        body: body,
        // If you want to allow changing category here, uncomment:
        // categoryId: widget.categoryId,
        updatedAt: DateTime.now(),
      );
      await box.put(widget.noteKey, updated);
    } else {
      // CREATE: add a new note under the tapped category
      final id = const Uuid().v4();
      final newNote = Note(
        id: id,
        title: title,
        body: body,
        categoryId: widget.categoryId, // <- tie to current category
        isPinned: false,
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await box.add(newNote);
    }

    if (mounted) Navigator.pop(context);
  }
}
