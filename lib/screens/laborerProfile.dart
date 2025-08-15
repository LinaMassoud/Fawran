import 'package:fawran/models/labour.dart';
import 'package:flutter/material.dart';

class LaborProfilePage extends StatefulWidget {
  final Laborer laborer;

  const LaborProfilePage({super.key, required this.laborer});

  @override
  State<LaborProfilePage> createState() => _LaborProfilePageState();
}

class _LaborProfilePageState extends State<LaborProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Labor Profile: ${widget.laborer.employeeName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              child: Icon(
                Icons.account_circle,
                size: 60,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.laborer.employeeName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Employee Number: ${widget.laborer.employeeNumber}"),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
