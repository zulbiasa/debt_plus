import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../main.dart';
import '../models/debt.dart';
import '../models/installment.dart';
import 'package:intl/intl.dart';

class AddDebtPage extends StatefulWidget {
  @override
  _AddDebtPageState createState() => _AddDebtPageState();
}

class _AddDebtPageState extends State<AddDebtPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _monthsController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();

  bool _isOwedToMe = false;
  bool _isInstallment = false;
  List<Installment> _installments = [];
  List<String> _suggestedNames = []; // Store name suggestions

  Future<void> _pickDueDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        _dueDateController.text = formatDate(selectedDate.toIso8601String());
      });
    }
  }

  void _fetchNameSuggestions(String input) {
    if (input.isEmpty) {
      setState(() {
        _suggestedNames = [];
      });
      return;
    }

    final debtBox = Hive.box<Debt>('debts');
    final names = debtBox.values.map((debt) => debt.name).toSet().toList();

    setState(() {
      _suggestedNames = names
          .where((name) => name.toLowerCase().startsWith(input.toLowerCase()))
          .toList();
    });
  }

  void _generateInstallments(int months) {
    _installments.clear();
    if (months <= 0) return;

    double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    double interestRate = double.tryParse(_interestController.text) ?? 0.0;
    double totalWithInterest = totalAmount + (totalAmount * (interestRate / 100));
    double monthlyPayment = totalWithInterest / months;

    DateTime startDate = DateTime.now();

    for (int i = 0; i < months; i++) {
      DateTime dueDate = DateTime(startDate.year, startDate.month + i + 1, startDate.day);
      _installments.add(Installment(
        amount: monthlyPayment,
        dueDate: DateFormat('dd/MM/yyyy').format(dueDate),
      ));
    }

    setState(() {});
  }



  void _submitDebt() async {
    if (_formKey.currentState!.validate()) {
      double amount = double.tryParse(_amountController.text) ?? 0.0;
      double interestRate = double.tryParse(_interestController.text) ?? 0.0;
      double totalAmount = amount + (amount * (interestRate / 100));

      final newDebt = Debt(
        name: _nameController.text,
        amount: totalAmount,
        dueDate: _dueDateController.text,
        purpose: _purposeController.text,
        isOwedToMe: _isOwedToMe,
        isCompleted: false,
        isInstallment: _isInstallment,
        paidAmount: 0.0,
        originalAmount: totalAmount,
      );

      final debtBox = Hive.box<Debt>('debts');
      await debtBox.add(newDebt);

      Navigator.pop(context);
    }
  }


  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        ),
        validator: (value) => value!.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _suggestedNames.clear();
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Add New Debt"),
          backgroundColor: Colors.blueAccent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📌 Autocomplete for Name
                  _buildTextField(
                    label: "Name",
                    controller: _nameController,
                    onChanged: _fetchNameSuggestions,
                  ),
                  if (_suggestedNames.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(maxHeight: 200),
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestedNames.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_suggestedNames[index]),
                            onTap: () {
                              setState(() {
                                _nameController.text = _suggestedNames[index];
                                _suggestedNames.clear();
                              });
                            },
                          );
                        },
                      ),
                    ),

                  _buildTextField(
                    label: "Total Amount (RM)",
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                  ),

                  _buildTextField(
                    label: "Due Date",
                    controller: _dueDateController,
                    readOnly: true,
                    onTap: () => _pickDueDate(context),
                  ),

                  _buildTextField(
                    label: "Purpose",
                    controller: _purposeController,
                  ),

                  SwitchListTile(
                    title: Text("Is this debt owed to me?"),
                    value: _isOwedToMe,
                    onChanged: (bool value) {
                      setState(() {
                        _isOwedToMe = value;
                      });
                    },
                  ),

                  SwitchListTile(
                    title: Text("Use Installment Plan?"),
                    value: _isInstallment,
                    onChanged: (bool value) {
                      setState(() {
                        _isInstallment = value;
                        if (!_isInstallment) _installments.clear();
                      });
                    },
                  ),

                  if (_isInstallment)
                    Column(
                      children: [
                        _buildTextField(
                          label: "Number of Months",
                          controller: _monthsController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            int months = int.tryParse(value) ?? 0;
                            _generateInstallments(months);
                          },
                        ),

                        _buildTextField(
                          label: "Interest Rate (%)",
                          controller: _interestController,
                          keyboardType: TextInputType.number,
                        ),


                        ..._installments.map((installment) {
                          return ListTile(
                            title: Text("Due Date: ${installment.dueDate}"),
                          );
                        }).toList(),

                      ],
                    ),

                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitDebt,
                      child: Text("Add Debt"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
