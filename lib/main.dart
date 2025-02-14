import 'package:debt_plus/screens/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'models/debt.dart';
import 'models/installment.dart'; // Import your Debt model
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized

  final appDocumentDir = await getApplicationDocumentsDirectory(); // Get app directory
  Hive.init(appDocumentDir.path); // Initialize Hive

  Hive.registerAdapter(DebtAdapter()); // Register the adapter
  Hive.registerAdapter(InstallmentAdapter());
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

String formatDate(String dateString) {
  try {
    DateTime date = DateTime.parse(dateString); // Convert string to DateTime
    return DateFormat('dd/MM/yyyy').format(date); // Change format here
  } catch (e) {
    return dateString; // Return original if parsing fails
  }
}