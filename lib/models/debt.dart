import 'package:hive/hive.dart';

import 'installment.dart';

part 'debt.g.dart';

@HiveType(typeId: 0)
class Debt extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double amount; // The original total amount of the debt

  @HiveField(2)
  String dueDate;

  @HiveField(3)
  String purpose;

  @HiveField(4)
  bool isOwedToMe;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6, defaultValue: false)
  bool isInstallment;

  @HiveField(7)
  List<Installment>? installments; // List of installment payments

  @HiveField(8)
  double paidAmount; // For flexible payments (how much has been paid)

  Debt({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.purpose,
    required this.isOwedToMe,
    required this.isCompleted,
    this.isInstallment = false,
    this.installments,
    this.paidAmount = 0.0, // Default to 0
  });

  double get remainingAmount => amount - paidAmount;
}
