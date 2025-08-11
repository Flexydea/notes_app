import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NoteEditorScreen extends StatelessWidget {
  const NoteEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Note')),
      body: Center(child: Text('Editor')),
    );
  }
}
