import 'package:flutter/material.dart';

class CategoryPicker extends StatefulWidget {
  final Color accentColor;
  final Function(String jobName, String? categoryId) onChanged;

  const CategoryPicker({super.key, required this.accentColor, required this.onChanged});

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  String? _selectedCategory;
  final TextEditingController _customJobController = TextEditingController();
  
  // Ta liste de métiers "Afrique"
  final List<Map<String, String>> _categories = [
    {'id': '1', 'name': 'Plombier'},
    {'id': '2', 'name': 'Électricien'},
    {'id': '3', 'name': 'Menuisier'},
    {'id': '4', 'name': 'Maçon'},
    {'id': '5', 'name': 'Frigoriste'},
    {'id': '6', 'name': 'Mécanicien'},
    {'id': 'other', 'name': 'Autre (Préciser...)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Métier principal',
            prefixIcon: const Icon(Icons.work_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _categories.map((cat) {
            return DropdownMenuItem(value: cat['id'], child: Text(cat['name']!));
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedCategory = val);
            if (val != 'other') {
              final name = _categories.firstWhere((c) => c['id'] == val)['name'];
              widget.onChanged(name!, val);
            }
          },
        ),
        if (_selectedCategory == 'other') ...[
          const SizedBox(height: 15),
          TextField(
            controller: _customJobController,
            decoration: InputDecoration(
              labelText: 'Saisissez votre métier',
              hintText: 'Ex: Développeur mobile, Coiffeur...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => widget.onChanged(val, null),
          ),
        ],
      ],
    );
  }
}