
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // Make sure to add this import
import 'package:student_db/screens/home.dart';
import 'package:student_db/theme/twitter_colors.dart';
// ignore: unused_import
import 'package:student_db/db_control/student.dart';  // Add this for StudentProvider

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap MaterialApp with ChangeNotifierProvider
    return ChangeNotifierProvider(
      create: (_) => StudentProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Student Database',
        // Your existing theme configuration remains the same
        theme: ThemeData(
          scaffoldBackgroundColor: TwitterColors.background,
          primaryColor: TwitterColors.accent,
          // ... rest of your theme configuration stays exactly the same
        ),
        home: const HomeScreen(),
      ),
    );
  }
}