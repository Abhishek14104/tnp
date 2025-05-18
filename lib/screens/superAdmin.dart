import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = false;

  /// Promote an existing student to admin
  Future<void> _makeAdmin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _loading = true);

    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found in database.')),
        );
        return;
      }

      final docId = userQuery.docs.first.id;

      await _firestore.collection('users').doc(docId).update({
        'role': 'admin',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User promoted to admin.')),
      );
      _emailController.clear();
    } catch (e) {
      print('Error making admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to make admin.')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Revert admin back to student
  Future<void> _removeAdmin(String docId) async {
    try {
      await _firestore.collection('users').doc(docId).update({
        'role': 'student',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin removed (reverted to student).')),
      );
    } catch (e) {
      print('Error removing admin: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Superadmin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Add admin by email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Enter email of existing user to promote to admin',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _makeAdmin,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Make Admin'),
            ),
            const Divider(height: 32),

            const Text(
              'Current Admins',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Real-time list of admins
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'admin')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final adminDocs = snapshot.data?.docs ?? [];

                  if (adminDocs.isEmpty) {
                    return const Center(child: Text('No admins found.'));
                  }

                  return ListView.builder(
                    itemCount: adminDocs.length,
                    itemBuilder: (context, index) {
                      final adminData = adminDocs[index].data() as Map<String, dynamic>;
                      final docId = adminDocs[index].id;

                      return ListTile(
                        title: Text(adminData['name'] ?? 'Unnamed'),
                        subtitle: Text(adminData['email'] ?? 'No Email'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeAdmin(docId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
