import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notifications_service.dart';
import '../models/reminder.dart';
import 'package:intl/intl.dart';

class AddReminderPage extends StatefulWidget {
  @override
  _AddReminderPageState createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _messageController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  TextEditingController _debtNameController = TextEditingController();

  String _repeatType = "Does Not Repeat"; // Default repeat type

  final NotiService notiService = NotiService();

  @override
  void initState() {
    super.initState();
    notiService.initNotification();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final reminderBox = Hive.box<Reminder>('reminders');

      Reminder newReminder = Reminder(
        debtName: _debtNameController.text.trim(),
        reminderDateTime: _selectedDateTime,
        message: _messageController.text.trim(),
      );

      await reminderBox.add(newReminder);

      await notiService.requestPermissions();
      await notiService.scheduleNotification(
        id: newReminder.key as int? ?? DateTime.now().millisecondsSinceEpoch,
        title: _debtNameController.text.isNotEmpty
            ? 'Debt Reminder: ${_debtNameController.text.trim()}'
            : 'Reminder',
        body: _messageController.text.trim(),
        hour: _selectedDateTime.hour,
        minute: _selectedDateTime.minute,
        repeatType: _repeatType , // Pass repeat type
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Reminder")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                    labelText: 'Reminder Message',
                    border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reminder message';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _debtNameController,
                decoration: InputDecoration(
                    labelText: 'Optional Debt Name (if related)',
                    border: OutlineInputBorder()),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Set Date & Time: ${DateFormat('MMM d, yyyy hh:mm a').format(_selectedDateTime)}",
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDateTime(context),
                    child: Text("Pick Date & Time"),
                  ),
                ],
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _repeatType,
                decoration: InputDecoration(labelText: "Repeat"),
                items: ["Does Not Repeat", "Daily", "Monthly"]
                    .map((repeatOption) => DropdownMenuItem(
                  value: repeatOption,
                  child: Text(repeatOption),
                ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    _repeatType = newValue!;
                  });
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveReminder,
                child: Text("Save Reminder"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
