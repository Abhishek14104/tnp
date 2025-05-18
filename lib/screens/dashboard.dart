import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  List<Map<String, dynamic>> eligibleCompanies = [];
  bool _companiesLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in if needed
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        userData = doc.data();
        _isLoading = false;
        setState(() {});

        // After loading user data, fetch eligible companies
        await _fetchEligibleCompanies();
      } else {
        setState(() {
          userData = null;
          _isLoading = false;
          _companiesLoading = false;
        });
      }
    } catch (e) {
      // Optionally show an error Snackbar here
      setState(() {
        _isLoading = false;
        _companiesLoading = false;
      });
    }
  }

  Future<void> _fetchEligibleCompanies() async {
  if (userData == null) {
    setState(() => _companiesLoading = false);
    return;
  }

  try {
    final batch = userData!['batch'];
    if (batch == null) {
      setState(() => _companiesLoading = false);
      return;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .where('eligibleBatches', arrayContains: batch)
        .get();

    eligibleCompanies = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    setState(() => _companiesLoading = false);
  } catch (e, stack) {
    print('Error fetching companies: $e');
    print(stack);
    setState(() => _companiesLoading = false);
  }
}

  String getCurrentYearOfStudy(int batch) {
    final now = DateTime.now();
    final startYear = batch - 4;

    int yearOfStudy = now.year - startYear;

    if (now.month > 7) {
      yearOfStudy += 1;
    }

    if (yearOfStudy < 1) return "Not started";
    if (yearOfStudy > 4) return "Graduated";

    switch (yearOfStudy) {
      case 1:
        return "1st Year";
      case 2:
        return "2nd Year";
      case 3:
        return "3rd Year";
      case 4:
        return "4th Year";
      default:
        return "Unknown";
    }
  }

  void _goToCompanyDetails(Map<String, dynamic> company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailsScreen(company: company),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return Scaffold(
        body: Center(child: Text('No user data found')),
      );
    }

    final name = userData!['name'] ?? 'N/A';
    final email = userData!['email'] ?? 'N/A';
    final mobile = userData!['mobile'] ?? 'N/A';
    final cgpa = userData!['cgpa']?.toString() ?? 'N/A';
    final batch = userData!['batch'] ?? 0;
    final currentYear = batch != 0 ? getCurrentYearOfStudy(batch) : 'N/A';

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Name: $name', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Email: $email', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Mobile: $mobile', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Current CGPA: $cgpa', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Batch (Graduation Year): $batch', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Current Year of Study: $currentYear', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            const Text('Eligible Companies:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (_companiesLoading)
              const Center(child: CircularProgressIndicator())
            else if (eligibleCompanies.isEmpty)
              const Text('No companies available for your batch yet.')
            else
              ...eligibleCompanies.map((company) {
                return ListTile(
                  title: Text(company['name'] ?? 'Unnamed Company'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _goToCompanyDetails(company),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

// Simple placeholder for company details page.
class CompanyDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> company;
  const CompanyDetailsScreen({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    final entries = company.entries.toList();

    return Scaffold(
      appBar: AppBar(title: Text(company['name'] ?? 'Company Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final key = entries[index].key;
            final value = entries[index].value;

            String displayValue;

            if (value is List) {
              displayValue = value.join(', ');
            } else if (value is Map) {
              displayValue = value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
            } else {
              displayValue = value.toString();
            }

            return ListTile(
              title: Text(
                key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(displayValue),
            );
          },
        ),
      ),
    );
  }
}
