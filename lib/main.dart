import 'package:flutter/material.dart';
import 'package:mental_model/mental_model.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MentalModel());
  }
}
