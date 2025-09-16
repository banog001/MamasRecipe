import 'package:flutter/material.dart';
import 'mealEntry.dart';
import 'mealPlanPreview.dart';

class CreateMealPlanPage extends StatefulWidget {
  const CreateMealPlanPage({super.key});

  @override
  State<CreateMealPlanPage> createState() => _CreateMealPlanPageState();
}

class _CreateMealPlanPageState extends State<CreateMealPlanPage> {
  String selectedPlanType = "Weight Loss";

  final Map<String, List<TextEditingController>> mealControllers = {
    "Breakfast": [TextEditingController()],
    "AM Snack": [TextEditingController()],
    "Lunch": [TextEditingController()],
    "PM Snack": [TextEditingController()],
    "Dinner": [TextEditingController()],
    "Midnight Snack": [TextEditingController()],
  };

  final Map<String, TimeOfDay> mealTimes = {
    "Breakfast": const TimeOfDay(hour: 6, minute: 0),
    "AM Snack": const TimeOfDay(hour: 9, minute: 0),
    "Lunch": const TimeOfDay(hour: 12, minute: 0),
    "PM Snack": const TimeOfDay(hour: 15, minute: 0),
    "Dinner": const TimeOfDay(hour: 18, minute: 0),
    "Midnight Snack": const TimeOfDay(hour: 21, minute: 0),
  };

  Future<void> _pickTime(String mealKey) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: mealTimes[mealKey]!,
    );
    if (picked != null) {
      setState(() {
        mealTimes[mealKey] = picked;
      });
    }
  }

  Widget buildMealRow(String mealName, String key) {
    final time = mealTimes[key]!;
    final formattedTime = time.format(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mealName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),

          // Dynamic textboxes
          Column(
            children: List.generate(mealControllers[key]!.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: TextField(
                  controller: mealControllers[key]![index],
                  decoration: const InputDecoration(
                    hintText: "Enter meal details",
                    border: OutlineInputBorder(),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // Buttons row
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Set Time:"),
                  const SizedBox(width: 10),
                  Text(
                    formattedTime,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _pickTime(key),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text("Edit Time",
                    style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    mealControllers[key]!.add(TextEditingController());
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text("Add", style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (mealControllers[key]!.length > 1) {
                      mealControllers[key]!.removeLast();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child:
                const Text("Delete", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        title: const Text("Create Meal Plan",
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Dropdown for meal plan type
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: DropdownButtonFormField<String>(
                value: selectedPlanType,
                items: const [
                  DropdownMenuItem(value: "Weight Loss", child: Text("Weight Loss")),
                  DropdownMenuItem(value: "Weight Gain", child: Text("Weight Gain")),
                  DropdownMenuItem(value: "Maintain Weight", child: Text("Maintain Weight")),
                  DropdownMenuItem(value: "Work Out", child: Text("Work Out")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedPlanType = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Meal Plan Type",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            buildMealRow("Breakfast", "Breakfast"),
            buildMealRow("AM Snack", "AM Snack"),
            buildMealRow("Lunch", "Lunch"),
            buildMealRow("PM Snack", "PM Snack"),
            buildMealRow("Dinner", "Dinner"),
            buildMealRow("Midnight Snack", "Midnight Snack"),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // ✅ Collect all meal data
                      List<MealEntry> meals = [];
                      mealControllers.forEach((key, controllers) {
                        meals.add(MealEntry(
                          name: key,
                          items: controllers
                              .map((c) => c.text)
                              .where((t) => t.isNotEmpty)
                              .toList(),
                          time: mealTimes[key]!,
                        ));
                      });

                      // ✅ Navigate to preview page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MealPlanPreviewPage(
                            planType: selectedPlanType,
                            meals: meals,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Next",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
