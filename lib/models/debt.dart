import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 0)
class Debt {
  @HiveField(0)
  String name;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String dueDate;

  @HiveField(3)
  String purpose;

  @HiveField(5)
  bool isOwedToMe;

  @HiveField(6)
  bool isCompleted;

  Debt({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.purpose,
    required this.isOwedToMe,
    this.isCompleted = false,
  });
}