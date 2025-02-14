import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 0)
class Debt extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String dueDate;

  @HiveField(3)
  String purpose;

  @HiveField(4)
  bool isOwedToMe;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  bool isInstallment;

  @HiveField(7)
  List<Map<String, dynamic>>? paymentHistory; // Track payments

  @HiveField(8)
  double paidAmount;

  Debt({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.purpose,
    required this.isOwedToMe,
    required this.isCompleted,
    this.isInstallment = false,
    this.paymentHistory,
    this.paidAmount = 0,
  });
}
