import 'package:debt_plus/screens/analytics_page.dart';
import 'package:debt_plus/screens/pay_debt_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/debt.dart';
import 'add_debt_page.dart';
import 'current_debt_page.dart';
import 'past_debt_page.dart';

class DashboardPage extends StatefulWidget {
  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late Box<Debt> debtBox;
  bool _isBoxInitialized = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _openBox().then((_) {
      setState(() {
        _isBoxInitialized = true;
      });
    });
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openBox() async {
    debtBox = await Hive.openBox<Debt>('debts');
  }

  double getTotalDebt(bool isOwedToMe) {
    if (!_isBoxInitialized) {
      return 0.0;
    }
    return debtBox.values
        .where((debt) => debt.isOwedToMe == isOwedToMe && !debt.isCompleted)
        .fold(0, (sum, debt) => sum + debt.amount);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBoxInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFE1F0FA),
      appBar: AppBar(
        centerTitle: true, // 👈 ADD THIS LINE
        title: Text("Debt Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Debt Overview
            Center(
              child: ValueListenableBuilder<Box<Debt>>(
                valueListenable: Hive.box<Debt>('debts').listenable(),
                builder: (context, box, _) {
                  double myDebt = getTotalDebt(false);
                  double othersDebtToMe = getTotalDebt(true);

                  return Card(
                    color: Colors.blue[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Total Debts Overview", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("My Debt", style: TextStyle(color: Colors.white, fontSize: 16)),
                                  Text(
                                    "RM ${myDebt.toStringAsFixed(2)}",
                                    style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Others' Debt to Me", style: TextStyle(color: Colors.white, fontSize: 16)),
                                  Text(
                                    "RM ${othersDebtToMe.toStringAsFixed(2)}",
                                    style: TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: "Current Debts"),
                Tab(text: "Past Debts"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  CurrentDebtPage(dashboardPageState: this),
                  PastDebtPage(dashboardPageState: this),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              height: 200,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.add, color: Colors.blueAccent),
                    title: Text("Add Debt"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddDebtPage()));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.notifications, color: Colors.blueAccent),
                    title: Text("Reminders"),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.bar_chart, color: Colors.blueAccent),
                    title: Text("Analytics"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AnalyticsPage()));
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: Icon(Icons.menu, color: Colors.white),
      ),
    );
  }

  Widget debtCard(Debt debt, dynamic key, BuildContext context, {bool isPastDebt = false}) {
    return Card(
      key: ValueKey(key),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.person, color: Colors.blueAccent),
        title: Text(debt.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${debt.purpose} • Due: ${debt.dueDate}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "RM ${debt.amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: debt.isOwedToMe ? Colors.green : Colors.redAccent,
              ),
            ),
            SizedBox(width: 10),
            if (!debt.isCompleted)
              IconButton(
                icon: Icon(Icons.payment, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PayDebtPage(debt: debt, debtKey: key)),
                  );
                },
              ),
          ],
        ),
        onLongPress: isPastDebt
            ? () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Delete Debt?"),
                content: Text(
                  "Are you sure you want to delete the debt to ${debt.name} for RM ${debt.amount.toStringAsFixed(2)}? This action is irreversible.",
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text("Delete", style: TextStyle(color: Colors.redAccent)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteDebt(key);
                    },
                  ),
                ],
              );
            },
          );
        }
            : () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Settle Debt?"),
                content: Text(
                  "Mark debt to ${debt.name} for RM ${debt.amount.toStringAsFixed(2)} as settled?",
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text("Settle", style: TextStyle(color: Colors.blueAccent)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _markAsCompleted(key);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }


  void _markAsCompleted(dynamic key) {
    final debtBox = Hive.box<Debt>('debts');
    Debt? existingDebt = debtBox.get(key);

    if (existingDebt != null) {
      existingDebt.isCompleted = true;
      debtBox.put(key, existingDebt);
      print("Debt updated with key: $key, isCompleted: ${existingDebt.isCompleted}");
      setState(() {});
    } else {
      print("Error: Debt not found with key $key!");
    }
  }

  void _deleteDebt(dynamic key) {
    final debtBox = Hive.box<Debt>('debts');
    debtBox.delete(key);
    print("Debt deleted with key: $key");
    setState(() {});
  }
}