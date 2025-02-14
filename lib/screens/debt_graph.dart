import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/debt.dart';
import 'package:intl/intl.dart';

class DebtGraph extends StatelessWidget {
  final Debt debt;

  DebtGraph({required this.debt});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Debt Payment Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(height: 300, child: LineChart(_buildChart())),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChart() {
    List<FlSpot> expectedSpots = _getExpectedPace();
    List<FlSpot> actualSpots = _getActualPayments();

    return LineChartData(
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: expectedSpots,
          isCurved: true,
          color: Colors.blue,
          dotData: FlDotData(show: true),
          barWidth: 3,
        ),
        LineChartBarData(
          spots: actualSpots,
          isCurved: true,
          color: Colors.green,
          dotData: FlDotData(show: true),
          barWidth: 3,
        ),
      ],
    );
  }

  List<FlSpot> _getExpectedPace() {
    if (!debt.isInstallment) return [];

    double installmentAmount = debt.amount / 6; // Assume 6-month plan
    List<FlSpot> spots = [];

    for (int i = 1; i <= 6; i++) {
      spots.add(FlSpot(i.toDouble(), installmentAmount * i));
    }

    return spots;
  }

  List<FlSpot> _getActualPayments() {
    if (debt.paymentHistory == null || debt.paymentHistory!.isEmpty) return [];

    List<FlSpot> spots = [];
    double totalPaid = 0.0;

    for (int i = 0; i < debt.paymentHistory!.length; i++) {
      totalPaid += debt.paymentHistory![i]["amount"];
      spots.add(FlSpot(i + 1.0, totalPaid));
    }

    return spots;
  }
}
