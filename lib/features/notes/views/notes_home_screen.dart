import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/widgets/app_drawer.dart';

class NotesHomeScreen extends StatelessWidget {
  const NotesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      drawer: const AppDrawer(), // reuse drawer
      body: const Center(child: Text('Home')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/edit'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
