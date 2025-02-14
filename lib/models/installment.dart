import 'package:hive/hive.dart';

part 'installment.g.dart';

@HiveType(typeId: 1)
class Installment extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String dueDate;

  @HiveField(2, defaultValue: false)
  bool isPaid;

  Installment({
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });
}
