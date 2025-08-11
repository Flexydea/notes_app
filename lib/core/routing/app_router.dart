import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/features/categories/views/categories_screen.dart';
import 'package:notes_app/features/notes/views/note_editor_screen.dart';
import 'package:notes_app/features/notes/views/notes_home_screen.dart';
import 'package:notes_app/features/settings/views/settings_screen.dart';

// lib/core/routing/app_router.dart
final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (c, s) => const NotesHomeScreen()),
    GoRoute(path: '/categories', builder: (c, s) => const CategoriesScreen()),
    GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
    GoRoute(
      path: '/edit',
      builder: (c, s) => const NoteEditorScreen(),
    ), // subpage
  ],
);
