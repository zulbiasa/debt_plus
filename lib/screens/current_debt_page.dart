import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/debt.dart';
import 'dashboard_page.dart';
import 'pay_debt_page.dart';

class CurrentDebtPage extends StatelessWidget {
  final DashboardPageState dashboardPageState;

  CurrentDebtPage({required this.dashboardPageState});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Debt>('debts').listenable(),
      builder: (context, Box<Debt> box, _) {
        if (!box.isOpen) {
          return Center(child: Text("Database Error: Box not opened."));
        }

        final activeDebts = box.values.where((debt) => !debt.isCompleted).toList();

        if (activeDebts.isEmpty) {
          return Center(child: Text("No current debts."));
        }

        final debtsByDate = <String, List<Debt>>{};
        for (var debt in activeDebts) {
          if (debt.dueDate.isNotEmpty) {
            debtsByDate.putIfAbsent(debt.dueDate, () => []).add(debt);
          } else {
            debtsByDate.putIfAbsent("No Due Date", () => []).add(debt);
          }
        }

        return ListView.builder(
          itemCount: debtsByDate.length,
          itemBuilder: (context, index) {
            final dueDates = debtsByDate.keys.toList();
            final dueDate = dueDates[index];
            final debtsForDate = debtsByDate[dueDate]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 15.0, left: 8.0, bottom: 8.0),
                  child: Text(
                    dueDate,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: debtsForDate.length,
                  itemBuilder: (context, debtIndex) {
                    final debt = debtsForDate[debtIndex];

                    dynamic debtKey;
                    box.keys.forEach((key) {
                      if (box.get(key) == debt) {
                        debtKey = key;
                      }
                    });

                    return Dismissible(
                      key: Key(debtKey.toString()),
                      direction: DismissDirection.startToEnd,
                      onDismissed: (direction) {
                        final updatedDebt = Debt(
                          name: debt.name,
                          amount: debt.amount,
                          dueDate: debt.dueDate,
                          purpose: debt.purpose,
                          isOwedToMe: debt.isOwedToMe,
                          isCompleted: true,
                        );
                        box.put(debtKey, updatedDebt);
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: 20),
                        color: Colors.green,
                        child: Icon(Icons.check, color: Colors.white, size: 32),
                      ),
                      child: dashboardPageState.debtCard(debt, debtKey, context),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
