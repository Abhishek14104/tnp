import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddOrEditCompanyScreen extends StatefulWidget {
  final DocumentSnapshot? docSnapshot;

  const AddOrEditCompanyScreen({super.key, this.docSnapshot});

  @override
  State<AddOrEditCompanyScreen> createState() => _AddOrEditCompanyScreenState();
}

class _AddOrEditCompanyScreenState extends State<AddOrEditCompanyScreen> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController minCgpaController;
  late TextEditingController batchesController;
  bool _isSaving = false;

  @override
  void initState() {
    final data = widget.docSnapshot?.data() as Map<String, dynamic>? ?? {};
    nameController = TextEditingController(text: data['name'] ?? '');
    descriptionController = TextEditingController(text: data['description'] ?? '');
    minCgpaController = TextEditingController(text: data['minCGPA']?.toString() ?? '');
    batchesController = TextEditingController(
      text: (data['eligibleBatches'] as List?)?.join(', ') ?? '',
    );
    super.initState();
  }

  Future<void> _saveCompany() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final cgpa = double.tryParse(minCgpaController.text.trim()) ?? 0.0;
    final batches = batchesController.text
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();

    if (name.isEmpty || description.isEmpty || batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final data = {
      'name': name,
      'description': description,
      'minCGPA': cgpa,
      'eligibleBatches': batches,
    };

    setState(() => _isSaving = true);

    try {
      if (widget.docSnapshot == null) {
        await FirebaseFirestore.instance.collection('companies').add(data);
      } else {
        await FirebaseFirestore.instance.collection('companies').doc(widget.docSnapshot!.id).update(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.docSnapshot == null ? 'Company added' : 'Company updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operation failed')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docSnapshot != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Company' : 'Add Company')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 16),

              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 100, maxHeight: 250),
                child: Scrollbar(
                  child: TextField(
                    controller: descriptionController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: minCgpaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Minimum CGPA'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: batchesController,
                decoration: const InputDecoration(
                  labelText: 'Eligible Batches (comma separated)',
                  hintText: 'e.g. 2024, 2025, 2026',
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveCompany,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(isEdit ? 'Update Company' : 'Add Company'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
