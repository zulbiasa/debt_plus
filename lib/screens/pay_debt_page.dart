import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/debt.dart';

class PayDebtPage extends StatefulWidget {
  final Debt debt;
  final dynamic debtKey;

  PayDebtPage({required this.debt, required this.debtKey});

  @override
  _PayDebtPageState createState() => _PayDebtPageState();
}

class _PayDebtPageState extends State<PayDebtPage> {
  final TextEditingController _amountController = TextEditingController();

  void _submitPayment() {
    final box = Hive.box<Debt>('debts');
    final double paymentAmount = double.tryParse(_amountController.text) ?? 0.0;

    if (paymentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Enter a valid amount."),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() {
      widget.debt.amount -= paymentAmount;
      widget.debt.paidAmount += paymentAmount;

      String formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

      widget.debt.paymentHistory ??= [];
      widget.debt.paymentHistory!.add({
        "amount": paymentAmount,
        "date": formattedDate,
      });
    });

    if (widget.debt.amount <= 0) {
      widget.debt.isCompleted = true;
    }

    box.put(widget.debtKey, widget.debt);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pay Debt")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Debt to: ${widget.debt.name}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Original Amount: RM ${widget.debt.originalAmount.toStringAsFixed(2)}", // Display original amount
                  style: TextStyle(fontSize: 16, color: Colors.grey)), // Style as needed
              Text("Total Remaining: RM ${widget.debt.amount.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 16)),
              Text("Total Paid: RM ${widget.debt.paidAmount.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 16, color: Colors.green)),
              SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Enter amount to pay"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitPayment,
                child: Text("Submit Payment"),
              ),
              SizedBox(height: 30),

              // Payment History
              Text("Payment History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Divider(),
              widget.debt.paymentHistory == null ||
                  widget.debt.paymentHistory!.isEmpty
                  ? Center(child: Text("No payments made yet"))
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: widget.debt.paymentHistory!.length,
                itemBuilder: (context, index) {
                  final payment = widget.debt.paymentHistory![index];
                  return ListTile(
                    leading: Icon(Icons.payment, color: Colors.green),
                    title: Text("RM ${payment["amount"]}"),
                    subtitle: Text("Paid on: ${payment["date"]}"),
                  );
                },
              ),

              SizedBox(height: 30),

              // Debt Payment Graph (No changes needed here for this feature)
              Text("Debt Payment Projection",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Container(
                height: 300,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            List<String> labels = ["1", "2", "3", "4"];
                            return Text(
                              labels[value.toInt() % labels.length] + " Month(s)",
                              style: TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        left: BorderSide(color: Colors.black, width: 2),
                        bottom: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generateSpots(), // Current payments (blue)
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: _generateExpectedSpots(), // Expected payments (green)
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dashArray: [5, 5], // Dotted Line
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    if (widget.debt.paymentHistory == null || widget.debt.paymentHistory!.isEmpty) {
      return [FlSpot(0, widget.debt.amount + widget.debt.paidAmount)];
    }

    double totalDebt = widget.debt.amount + widget.debt.paidAmount;
    double remainingDebt = totalDebt;
    List<FlSpot> spots = [];

    for (int i = 0; i < widget.debt.paymentHistory!.length; i++) {
      double paidSoFar = widget.debt.paymentHistory!.sublist(0, i + 1).fold(0.0, (sum, item) => sum + (item["amount"] as double));
      remainingDebt = totalDebt - paidSoFar;
      spots.add(FlSpot((i + 1).toDouble(), remainingDebt));
    }

    return spots;
  }


  List<FlSpot> _generateExpectedSpots() {
    double totalDebt = widget.debt.amount + widget.debt.paidAmount;
    double monthlyPayment = totalDebt / 4;

    return List.generate(4, (index) {
      return FlSpot(index.toDouble() + 1, totalDebt - (monthlyPayment * (index + 1)));
    });
  }
}