import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 1)
class Payment extends HiveObject {
  @HiveField(0)
  double amount; // Amount paid

  @HiveField(1)
  String date; // Date of payment

  Payment({
    required this.amount,
    required this.date,
  });
}
