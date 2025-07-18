import 'dart:io';

import 'package:fawran/models/labour.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LaborProfilePage extends StatefulWidget {
  final Laborer laborer;

  const LaborProfilePage({required this.laborer});

  @override
  _LaborProfilePageState createState() => _LaborProfilePageState();
}

class _LaborProfilePageState extends State<LaborProfilePage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize YouTube player controller with a sample video ID
    _controller = YoutubePlayerController(
      initialVideoId: 'dQw4w9WgXcQ', // Replace with the YouTube video ID
      flags: YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Labor Profile: ${widget.laborer.employeeName}'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
           CircleAvatar(
  radius: 50,
  backgroundColor: Colors.grey[200], // Optional background color
  child: Icon(
    Icons.account_circle, // Default user icon
    size: 60, // Adjust the size of the icon
    color: Colors.grey[600], // Icon color
  ),
),
            SizedBox(height: 16),
            Text(widget.laborer.employeeName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Employee Number: ${widget.laborer.employeeNumber}"),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Trigger the CV download action
                final byteData = await rootBundle.load('assets/cvs/cv.pdf');
                final buffer = byteData.buffer.asUint8List();
                final filePath = await _saveFile(buffer, 'cv.pdf');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CV saved to $filePath')));
              },
              child: Text('Download CV'),
            ),
            SizedBox(height: 16),
            // Embedded YouTube video player
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black,
              ),
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to save file from assets
  Future<String> _saveFile(Uint8List bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
