import 'package:flutter/material.dart';

class MealEntry {
  final String name;
  final List<String> items;
  final TimeOfDay time;

  MealEntry({
    required this.name,
    required this.items,
    required this.time,
  });
}
