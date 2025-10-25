import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageMealPlansPage extends StatefulWidget {
  const ManageMealPlansPage({Key? key}) : super(key: key);

  @override
  State<ManageMealPlansPage> createState() => _ManageMealPlansPageState();
}

class _ManageMealPlansPageState extends State<ManageMealPlansPage> {
  static const String _primaryFontFamily = 'YourFontFamily'; // Replace with your font
  static const Color _primaryColor = Colors.green;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Meal Plans',
          style: TextStyle(
            fontFamily: _primaryFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mealPlans')
            .where('owner', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No meal plans found',
                    style: TextStyle(
                      fontFamily: _primaryFontFamily,
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    _primaryColor.withOpacity(0.1),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Meal Plan Name',
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Created',
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Actions',
                        style: TextStyle(
                          fontFamily: _primaryFontFamily,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  rows: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            data['name'] ?? 'Unnamed Plan',
                            style: const TextStyle(
                              fontFamily: _primaryFontFamily,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 200,
                            child: Text(
                              data['description'] ?? 'No description',
                              style: const TextStyle(
                                fontFamily: _primaryFontFamily,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            data['createdAt'] != null
                                ? _formatDate(data['createdAt'])
                                : 'N/A',
                            style: const TextStyle(
                              fontFamily: _primaryFontFamily,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Edit',
                                onPressed: () => _editMealPlan(doc.id, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _deleteMealPlan(doc.id, data['name']),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewMealPlan(),
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _editMealPlan(String mealPlanId, Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['name'] ?? '');
    final descriptionController = TextEditingController(text: currentData['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Edit Meal Plan',
          style: TextStyle(fontFamily: _primaryFontFamily),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Meal Plan Name',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: _primaryFontFamily),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: _primaryFontFamily),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a meal plan name')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('mealPlans')
                    .doc(mealPlanId)
                    .update({
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meal plan updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating meal plan: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteMealPlan(String mealPlanId, String? mealPlanName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Meal Plan',
          style: TextStyle(fontFamily: _primaryFontFamily),
        ),
        content: Text(
          'Are you sure you want to delete "${mealPlanName ?? 'this meal plan'}"?',
          style: const TextStyle(fontFamily: _primaryFontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('mealPlans')
                    .doc(mealPlanId)
                    .delete();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meal plan deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting meal plan: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createNewMealPlan() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Create New Meal Plan',
          style: TextStyle(fontFamily: _primaryFontFamily),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Meal Plan Name',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: _primaryFontFamily),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: _primaryFontFamily),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a meal plan name')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('mealPlans').add({
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'dietitianId': currentUserId,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meal plan created successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating meal plan: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}