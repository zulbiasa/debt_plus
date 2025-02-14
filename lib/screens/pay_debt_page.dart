import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/debt.dart';

class PayDebtPage extends StatefulWidget {
  final Debt debt;
  final dynamic debtKey; // Accept debtKey

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
    });

    if (widget.debt.amount <= 0) {
      widget.debt.isCompleted = true;
    }

    box.put(widget.debtKey, widget.debt); // Save changes to Hive

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pay Debt")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Debt to: ${widget.debt.name}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Total Remaining: RM ${widget.debt.amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 16)),
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
          ],
        ),
      ),
    );
  }
}
