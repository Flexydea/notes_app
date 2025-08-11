import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notes_app/data/models/category.dart';
import 'package:notes_app/data/services/hive_service.dart';

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const _BootGate(),
    );
  }
}

/// TEMP screen: verifies Hive + seeding. Replace with router next.
class CategoriesProbeScreen extends StatelessWidget {
  const CategoriesProbeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Category>(HiveService.categoriesBoxName);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories Probe')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Category> b, _) {
          if (b.isEmpty)
            return const Center(child: Text('No categories found'));
          return ListView.builder(
            itemCount: b.length,
            itemBuilder: (context, i) {
              final cat = b.getAt(i);
              if (cat == null) return const SizedBox.shrink();
              return ListTile(
                title: Text(cat.name),
                subtitle: Text(cat.id),
                trailing: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(cat.colorHex),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BootGate extends StatefulWidget {
  const _BootGate({super.key});

  @override
  State<_BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<_BootGate> {
  late Future<void> _boot;

  @override
  void initState() {
    super.initState();
    _boot = HiveService.init(); // This opens boxes before probe runs
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _boot,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Init error:\n${snapshot.error}')),
          );
        }
        return const CategoriesProbeScreen();
      },
    );
  }
}
