import 'package:hive/hive.dart';

part 'reminder.g.dart'; // Ensure you run build_runner after creating this

@HiveType(typeId: 2) // Use a different typeId than Debt (0)
class Reminder extends HiveObject {
  @HiveField(0)
  String? debtName; // Optional: Name of the debt it's related to (can be null for general reminders)

  @HiveField(1)
  DateTime reminderDateTime;

  @HiveField(2)
  String message;

  Reminder({
    this.debtName,
    required this.reminderDateTime,
    required this.message,
  });
}