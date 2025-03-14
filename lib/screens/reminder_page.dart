import 'dart:io';
import 'package:debt_plus/models/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import 'add_reminder_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class RemindersPage extends StatefulWidget {
  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  late Box<Reminder> reminderBox;
  bool _isBoxInitialized = false;

  @override
  void initState() {
    super.initState();
    _openBox().then((_) {
      setState(() {
        _isBoxInitialized = true;
      });
    });
  }

  Future<void> _openBox() async {
    reminderBox = await Hive.openBox<Reminder>('reminders');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBoxInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text("Reminders")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Reminders")),
      body: ValueListenableBuilder<Box<Reminder>>(
        valueListenable: reminderBox.listenable(),
        builder: (context, box, _) {
          if (box.values.isEmpty) {
            return Center(child: Text("No reminders set yet."));
          }
          return ListView.builder(
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final reminder = box.getAt(index);
              if (reminder == null) {
                return SizedBox.shrink();
              }
              return _reminderCard(reminder, index);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => AddReminderPage()));


        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _reminderCard(Reminder reminder, int index) {
    return Card(
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.alarm, color: Colors.orange),
        title: Text(reminder.message, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.debtName != null && reminder.debtName!.isNotEmpty)
              Text("For debt: ${reminder.debtName}"),
            Text(
              "Time: ${DateFormat('MMM d, yyyy hh:mm a').format(reminder.reminderDateTime)}",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () {
            _deleteReminder(index, reminder, reminder.key);
          },
        ),
      ),
    );
  }

  void _deleteReminder(int index, Reminder reminder, int id) async {
    NotiService().cancelNoti(id);
    await reminderBox.deleteAt(index);
  }
}