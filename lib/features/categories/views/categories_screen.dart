import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/widgets/app_drawer.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      drawer: const AppDrawer(), // reuse drawer

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.work),
            title: Text('Work'),
            trailing: Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Personal'),
            trailing: Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Shopping'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add category screen later
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
