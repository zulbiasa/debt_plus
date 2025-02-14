import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';

class AddDebtPage extends StatefulWidget {
  @override
  _AddDebtPageState createState() => _AddDebtPageState();
}

class _AddDebtPageState extends State<AddDebtPage> {
  final _formKey = GlobalKey<FormState>();
  late Box<Debt> debtBox;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  DateTime? _selectedDate;
  bool _isOwedToMe = false;

  List<String> _matchingNames = []; // Store filtered names

  @override
  void initState() {
    super.initState();
    _openBox();
    _nameController.addListener(_filterNames); // Listen for name changes
  }

  @override
  void dispose() {
    _nameController.removeListener(_filterNames);
    _nameController.dispose();
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _openBox() async {
    debtBox = await Hive.openBox<Debt>('debts');
    setState(() {});
  }

  void _filterNames() {
    final input = _nameController.text.toLowerCase();

    if (input.isEmpty) {
      setState(() {
        _matchingNames = [];
      });
      return;
    }

    final pastNames = debtBox.values.map((debt) => debt.name).toSet().toList();

    setState(() {
      _matchingNames = pastNames
          .where((name) => name.toLowerCase().contains(input))
          .toList();
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addDebt() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final newDebt = Debt(
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        dueDate: DateFormat('dd MMM yyyy').format(_selectedDate!),
        purpose: _purposeController.text,
        isOwedToMe: _isOwedToMe,
        isCompleted: false,
      );

      debtBox.add(newDebt);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Debt"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "To Whom",
                  suffixIcon: _matchingNames.isNotEmpty
                      ? Icon(Icons.search, color: Colors.grey)
                      : null,
                ),
                validator: (value) => value!.isEmpty ? "Enter name" : null,
              ),
              if (_matchingNames.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    children: _matchingNames.map((name) {
                      return ListTile(
                        title: Text(name),
                        onTap: () {
                          _nameController.text = name;
                          setState(() {
                            _matchingNames = [];
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount (RM)"),
                validator: (value) => value!.isEmpty ? "Enter amount" : null,
              ),
              SizedBox(height: 15),
              Text("Due Date", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => _pickDate(context),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _selectedDate == null ? "Select Due Date" : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(labelText: "Purpose"),
                validator: (value) => value!.isEmpty ? "Enter purpose" : null,
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Text("Is this money owed to you?", style: TextStyle(fontSize: 16)),
                  Spacer(),
                  Switch(
                    value: _isOwedToMe,
                    onChanged: (value) {
                      setState(() {
                        _isOwedToMe = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addDebt,
                  child: Text("Save Debt"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
