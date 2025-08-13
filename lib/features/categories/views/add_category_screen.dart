import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:notes_app/data/models/category.dart';
import 'package:notes_app/data/services/hive_service.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Palets of colors to choose from

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.red,
    Colors.blueGrey,
    Colors.teal,
    Colors.brown,
  ];

  //List of small set of icons

  final List<IconData> _iconOptions = [
    Icons.label,
    Icons.work,
    Icons.person,
    Icons.lightbulb,
    Icons.shopping_cart,
    Icons.school,
    Icons.bookmark,
    Icons.favorite,
    Icons.home,
    Icons.task_alt,
    Icons.event,
    Icons.note,
    Icons.movie,
    Icons.fitness_center,
    Icons.warning,
    Icons.flight,
  ];

  // active current selectors on the form
  late Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.label;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Category')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //category name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g Gym',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a name'
                    : null,
              ),

              const SizedBox(height: 20),

              //Color picker title
              Row(
                children: [
                  const Text(
                    'Pick a Color',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // color picker( wrap of circular watches)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colorOptions.map((c) {
                  final isActive = c.value == _selectedColor.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: isActive ? 3 : 1,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              //icon picker title
              const Text(
                'Pick Icon',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              //Icon picker grid
              SizedBox(
                height: 160,
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: _iconOptions.length,
                  itemBuilder: (context, index) {
                    final icon = _iconOptions[index];
                    final isActive = _selectedIcon == icon;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = icon),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black12,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // const Spacer(),

              // NEW: Save button (validates & writes to Hive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveCategory,
                  child: const Text('Save Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Save handler
  void _saveCategory() {
    if (!_formKey.currentState!.validate()) return;

    final uuid = const Uuid();
    HiveService.categoriesBox.add(
      Category(
        id: uuid.v4(),
        name: _nameController.text.trim(),
        colorHex: _selectedColor.value,
        iconCodePoint: _selectedIcon.codePoint,
      ),
    );

    Navigator.pop(context); // back to list
  }
}
