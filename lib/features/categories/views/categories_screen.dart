import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notes_app/core/widgets/app_drawer.dart';
import 'package:notes_app/data/models/category.dart';
import 'package:notes_app/data/services/hive_service.dart';
import 'package:notes_app/features/categories/views/add_category_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box =
        HiveService.categoriesBox; // NEW: Get categories box from HiveService

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      drawer: const AppDrawer(),

      // NEW: Use ValueListenableBuilder to update UI when Hive data changes
      body: ValueListenableBuilder(
        valueListenable: box.listenable(), // NEW
        builder: (context, Box<Category> box, _) {
          if (box.isEmpty) {
            // NEW: Show placeholder if no categories
            return const Center(child: Text('No categories yet.'));
          }

          final categories = box.values
              .toList(); // NEW: Convert box values to list

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                // NEW: Display icon from category model or default label icon
                leading: Icon(
                  IconData(
                    category.iconCodePoint ?? Icons.label.codePoint,
                    fontFamily: 'MaterialIcons',
                  ),
                  color: Color(category.colorHex),
                ),
                title: Text(category.name), // NEW: Category name from Hive
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to category-specific notes later
                },
              );
            },
          );
        },
      ),

      // FAB for adding a category (next step)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCategoryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
