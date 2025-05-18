import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_edit_company_screen.dart'; // Make sure this file exists

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> _deleteCompany(String id) async {
    await FirebaseFirestore.instance.collection('companies').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('companies').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final companies = snapshot.data?.docs ?? [];

          if (companies.isEmpty) return const Center(child: Text('No companies added yet'));

          return ListView.builder(
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final doc = companies[index];
              final data = doc.data() as Map<String, dynamic>?;

              final eligibleBatches = data?['eligibleBatches']?.join(', ') ?? 'N/A';
              final minCgpa = data?['minCGPA']?.toString() ?? 'N/A';
              final name = data?['name'] ?? 'Unnamed';

              return ListTile(
                title: Text(name),
                subtitle: Text('Min CGPA: $minCgpa | Batches: $eligibleBatches'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddOrEditCompanyScreen(docSnapshot: doc),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCompany(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddOrEditCompanyScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
