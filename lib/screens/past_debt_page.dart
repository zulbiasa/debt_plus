import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/debt.dart';
import 'dashboard_page.dart';

class PastDebtPage extends StatelessWidget {
  final DashboardPageState dashboardPageState;

  PastDebtPage({required this.dashboardPageState});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder( // No Expanded here
      valueListenable: Hive.box<Debt>('debts').listenable(),
      builder: (context, Box<Debt> box, _) {
        if (!box.isOpen) { // 🛠️ Check if box is open
          return Center(child: Text("Database Error: Box not opened.")); // Handle error
        }

        final pastDebts = box.values
            .where((debt) => debt.isCompleted)
            .toList();

        if (pastDebts.isEmpty) {
          return Center(child: Text("No past debts."));
        }

        // 1. Group debts by due date
        final debtsByDate = <String, List<Debt>>{};
        for (var debt in pastDebts) {
          if (debt.dueDate != null) {
            if (!debtsByDate.containsKey(debt.dueDate)) {
              debtsByDate[debt.dueDate!] = [];
            }
            debtsByDate[debt.dueDate!]!.add(debt);
          } else {
            if (!debtsByDate.containsKey("No Due Date")) {
              debtsByDate["No Due Date"] = [];
            }
            debtsByDate["No Due Date"]!.add(debt);
          }
        }

        // 2. Display sections with date headers and debt cards
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
                    dueDate, // Section header is the due date
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
                    return dashboardPageState.debtCard(debt, debtKey, isPastDebt: true);
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