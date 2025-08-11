import 'package:flutter/material.dart';
import 'package:notes_app/app.dart';
import 'package:notes_app/data/models/category.dart';
import 'package:notes_app/data/models/note.dart';
import 'package:notes_app/data/services/hive_service.dart';
import 'package:hive/hive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Register Adapters before opening boxes
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(CategoryAdapter());

  await HiveService.init();

  runApp(const NotesApp());
}
