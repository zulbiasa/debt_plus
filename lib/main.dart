import 'package:debt_plus/screens/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'models/debt.dart'; // Import your Debt model

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized

  final appDocumentDir = await getApplicationDocumentsDirectory(); // Get app directory
  Hive.init(appDocumentDir.path); // Initialize Hive

  Hive.registerAdapter(DebtAdapter()); // Register the adapter
  await Hive.openBox<Debt>('debts'); // Open the box before running app

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardPage(),
    );
  }
}