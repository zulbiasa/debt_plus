import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/debt.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Box<Debt> debtBox;
  bool _isBoxOpen = false; // Add a flag to track box open status

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _openBox();
  }

  void _openBox() async {
    debtBox = await Hive.openBox<Debt>('debts');
    setState(() {
      _isBoxOpen = true; // Set the flag to true after box is opened
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analytics"),
        backgroundColor: Colors.blueAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Current"),
            Tab(text: "Past"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalytics(false), // Current Debts
          _buildAnalytics(true), // Past Debts
        ],
      ),
    );
  }

  Widget _buildAnalytics(bool isPast) {
    if (!_isBoxOpen) { // Check the flag instead of debtBox.isOpen directly in build method
      return Center(child: CircularProgressIndicator());
    }

    final allDebts = debtBox.values.toList();
    final filteredDebts = allDebts.where((debt) => debt.isCompleted == isPast).toList();

    double totalDebt = filteredDebts.fold(0, (sum, debt) => sum + debt.amount);
    double totalCollected = filteredDebts.where((debt) => debt.isOwedToMe).fold(0, (sum, debt) => sum + debt.amount);
    double totalOwed = totalDebt - totalCollected;

    Map<String, double> peopleOwedToMe = {};
    Map<String, double> peopleIOwe = {};

    for (var debt in filteredDebts) {
      if (debt.isOwedToMe) {
        peopleOwedToMe[debt.name] = (peopleOwedToMe[debt.name] ?? 0) + debt.amount;
      } else {
        peopleIOwe[debt.name] = (peopleIOwe[debt.name] ?? 0) + debt.amount;
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total Debt: RM ${totalOwed.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Total Collected: RM ${totalCollected.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 20),
            _buildPieChart(totalCollected, totalOwed ),
            SizedBox(height: 20),
            Column(
              children: [
                _buildTopPeople("Top 5 People You Owe", peopleIOwe),
                _buildTopPeople("Top 5 People Owing You", peopleOwedToMe),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(double owedToMe, double owedByMe) {
    if (!_isBoxOpen) { // Add check here as well, though it should be already loaded by this point
      return Center(child: CircularProgressIndicator());
    }
    if (owedToMe == 0 && owedByMe == 0) {
      return Center(child: Text("No debt data available for chart"));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 150,
          width: 150,
          child: PieChart(
            PieChartData(
              sections: [
                if (owedToMe > 0)
                  PieChartSectionData(
                      value: owedToMe,
                      color: Colors.green,
                      radius: 50,
                      showTitle: false
                  ),
                if (owedByMe > 0)
                  PieChartSectionData(
                      value: owedByMe,
                      color: Colors.red,
                      radius: 50,
                      showTitle: false
                  ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        SizedBox(width: 20),
        Column( // Legend on right side
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem("I Owe", Colors.red, owedByMe, owedToMe + owedByMe),
            _legendItem("Owed to Me", Colors.green, owedToMe, owedToMe + owedByMe),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String title, Color color, double value, double total) {
    if (value == 0) return SizedBox.shrink();
    double percentage = (value / total) * 100;
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        SizedBox(width: 8),
        Text("$title: RM ${value.toStringAsFixed(2)} (${percentage.toStringAsFixed(2)}%)"),
      ],
    );
  }

  Widget _buildTopPeople(String title, Map<String, double> people) {
    if (!_isBoxOpen) { // Add check here as well for safety
      return Center(child: CircularProgressIndicator());
    }
    final sortedPeople = people.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedPeople.isEmpty) {
      return Center(child: Text("No data available for $title"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ...sortedPeople.take(5).map((entry) => ListTile(
          title: Text(entry.key),
          trailing: Text("RM ${entry.value.toStringAsFixed(2)}",
              style: TextStyle(fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }
}