import 'package:debt_plus/models/notifications_service.dart';
import 'package:debt_plus/screens/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider; // Import path_provider with alias
import 'models/debt.dart';
import 'package:intl/intl.dart';
import 'models/reminder.dart'; // Import timezone

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotiService().initNotification();
  NotiService().requestPermissions();

  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  Hive.registerAdapter(DebtAdapter());
  Hive.registerAdapter(ReminderAdapter());

  await Hive.openBox<Debt>('debts');
  await Hive.openBox<Reminder>('reminders');

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