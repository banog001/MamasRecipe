import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'createMealPlan.dart';

class ManageMealPlansPage extends StatefulWidget {
  const ManageMealPlansPage({Key? key}) : super(key: key);

  @override
  State<ManageMealPlansPage> createState() => _ManageMealPlansPageState();
}

class _ManageMealPlansPageState extends State<ManageMealPlansPage> {
  static const String _primaryFontFamily = 'YourFontFamily';
  static const Color _primaryColor = Colors.green;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Color _cardBgColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[850]!
        : Colors.white;
  }

  TextStyle _cardTitleStyle(BuildContext context) {
    return const TextStyle(
      fontFamily: _primaryFontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
  }

  TextStyle _cardBodyTextStyle(BuildContext context) {
    return const TextStyle(
      fontFamily: _primaryFontFamily,
      fontSize: 14,
    );
  }

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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 380,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildMealPlanCard(context, doc, data);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateMealPlanPage()),
          );
        },

        backgroundColor: _primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMealPlanCard(
      BuildContext context,
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: _cardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Plan Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['planType'] ?? 'Meal Plan',
                    style: _cardBodyTextStyle(context).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: _primaryColor,
                    ),
                  ),
                ),
                if (data['timestamp'] != null && data['timestamp'] is Timestamp)
                  Text(
                    DateFormat('MMM dd, yyyy').format(
                      (data['timestamp'] as Timestamp).toDate(),
                    ),
                    style: TextStyle(
                      fontFamily: _primaryFontFamily,
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),

            // Meal Table
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                  },
                  border: TableBorder.all(
                    color: Colors.grey[300]!,
                    width: 0.5,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  children: [
                    _buildTableRow('Breakfast', data['breakfast'], data['breakfastTime'], isHeader: false),
                    _buildTableRow('AM Snack', data['amSnack'], data['amSnackTime'], isHeader: false),
                    _buildTableRow('Lunch', data['lunch'], data['lunchTime'], isHeader: false),
                    _buildTableRow('PM Snack', data['pmSnack'], data['pmSnackTime'], isHeader: false),
                    _buildTableRow('Dinner', data['dinner'], data['dinnerTime'], isHeader: false),
                    _buildTableRow('Midnight Snack', data['midnightSnack'], data['midnightSnackTime'], isHeader: false),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like Count
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                      '${data['likeCounts'] ?? 0}',
                      style: const TextStyle(
                        fontFamily: _primaryFontFamily,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                      tooltip: 'Edit',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: () => _editMealPlan(doc.id, data),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      tooltip: 'Delete',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: () => _deleteMealPlan(doc.id, data['planType']),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String? meal, String? time, {bool isHeader = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: _primaryFontFamily,
              fontSize: 12,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            meal ?? 'N/A',
            style: TextStyle(
              fontFamily: _primaryFontFamily,
              fontSize: 12,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            time ?? '',
            style: TextStyle(
              fontFamily: _primaryFontFamily,
              fontSize: 11,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  void _editMealPlan(String mealPlanId, Map<String, dynamic> currentData) {
    String selectedPlanType = currentData['planType'] ?? 'Weight Loss';
    final breakfastController = TextEditingController(text: currentData['breakfast'] ?? '');
    final breakfastTimeController = TextEditingController(text: currentData['breakfastTime'] ?? '');
    final amSnackController = TextEditingController(text: currentData['amSnack'] ?? '');
    final amSnackTimeController = TextEditingController(text: currentData['amSnackTime'] ?? '');
    final lunchController = TextEditingController(text: currentData['lunch'] ?? '');
    final lunchTimeController = TextEditingController(text: currentData['lunchTime'] ?? '');
    final pmSnackController = TextEditingController(text: currentData['pmSnack'] ?? '');
    final pmSnackTimeController = TextEditingController(text: currentData['pmSnackTime'] ?? '');
    final dinnerController = TextEditingController(text: currentData['dinner'] ?? '');
    final dinnerTimeController = TextEditingController(text: currentData['dinnerTime'] ?? '');
    final midnightSnackController = TextEditingController(text: currentData['midnightSnack'] ?? '');
    final midnightSnackTimeController = TextEditingController(text: currentData['midnightSnackTime'] ?? '');

    final List<String> planTypes = [
      'Weight Loss',
      'Weight Gain',
      'Maintain Weight',
      'Workout',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Edit Meal Plan',
            style: TextStyle(fontFamily: _primaryFontFamily),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedPlanType,
                    decoration: const InputDecoration(
                      labelText: 'Plan Type',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(
                      fontFamily: _primaryFontFamily,
                      color: Colors.black87,
                    ),
                    items: planTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedPlanType = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMealInputPair('Breakfast', breakfastController, breakfastTimeController),
                  const SizedBox(height: 16),
                  _buildMealInputPair('AM Snack', amSnackController, amSnackTimeController),
                  const SizedBox(height: 16),
                  _buildMealInputPair('Lunch', lunchController, lunchTimeController),
                  const SizedBox(height: 16),
                  _buildMealInputPair('PM Snack', pmSnackController, pmSnackTimeController),
                  const SizedBox(height: 16),
                  _buildMealInputPair('Dinner', dinnerController, dinnerTimeController),
                  const SizedBox(height: 16),
                  _buildMealInputPair('Midnight Snack', midnightSnackController, midnightSnackTimeController),
                ],
              ),
            ),
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
                      .update({
                    'planType': selectedPlanType,
                    'breakfast': breakfastController.text.trim(),
                    'breakfastTime': breakfastTimeController.text.trim(),
                    'amSnack': amSnackController.text.trim(),
                    'amSnackTime': amSnackTimeController.text.trim(),
                    'lunch': lunchController.text.trim(),
                    'lunchTime': lunchTimeController.text.trim(),
                    'pmSnack': pmSnackController.text.trim(),
                    'pmSnackTime': pmSnackTimeController.text.trim(),
                    'dinner': dinnerController.text.trim(),
                    'dinnerTime': dinnerTimeController.text.trim(),
                    'midnightSnack': midnightSnackController.text.trim(),
                    'midnightSnackTime': midnightSnackTimeController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
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
      ),
    );
  }

  Widget _buildMealInputPair(String label, TextEditingController mealController, TextEditingController timeController) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: mealController,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: _primaryFontFamily),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: timeController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Time',
              border: OutlineInputBorder(),
              hintText: '6:00 AM',
              suffixIcon: Icon(Icons.access_time),
            ),
            style: const TextStyle(fontFamily: _primaryFontFamily),
            onTap: () async {
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: _parseTimeOfDay(timeController.text) ?? TimeOfDay.now(),
              );
              if (pickedTime != null) {
                timeController.text = _formatTimeOfDay(pickedTime);
              }
            },
          ),
        ),
      ],
    );
  }

  TimeOfDay? _parseTimeOfDay(String timeString) {
    if (timeString.isEmpty) return null;
    try {
      final parts = timeString.split(' ');
      if (parts.length != 2) return null;

      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;

      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final String period = parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _deleteMealPlan(String mealPlanId, String? planType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Meal Plan',
          style: TextStyle(fontFamily: _primaryFontFamily),
        ),
        content: Text(
          'Are you sure you want to delete the "${planType ?? 'this'}" meal plan?',
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
}