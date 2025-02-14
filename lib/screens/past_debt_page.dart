import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/debt.dart';
import 'dashboard_page.dart';

class PastDebtPage extends StatelessWidget {
  final DashboardPageState dashboardPageState;

  PastDebtPage({required this.dashboardPageState});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Debt>('debts').listenable(),
      builder: (context, Box<Debt> box, _) {
        if (!box.isOpen) {
          return Center(child: Text("Database Error: Box not opened."));
        }

        final pastDebts = box.values.where((debt) => debt.isCompleted).toList();

        if (pastDebts.isEmpty) {
          return Center(child: Text("No past debts."));
        }

        final debtsByDate = <String, List<Debt>>{};
        for (var debt in pastDebts) {
          final dateKey = debt.dueDate ?? "No Due Date";
          debtsByDate.putIfAbsent(dateKey, () => []).add(debt);
        }

        return ListView.builder(
          itemCount: debtsByDate.length,
          itemBuilder: (context, index) {
            final dueDate = debtsByDate.keys.elementAt(index);
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

                    // 🔹 Efficiently retrieve key
                    final debtKey = box.keyAt(box.values.toList().indexOf(debt));

                    return dashboardPageState.debtCard(debt, debtKey, context, isPastDebt: true);


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
