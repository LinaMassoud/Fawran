import 'dart:io';
import 'dart:typed_data';

import 'package:fawran/models/labour.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class LaborProfilePage extends StatefulWidget {
  final Laborer laborer;

  const LaborProfilePage({super.key, required this.laborer});

  @override
  State<LaborProfilePage> createState() => _LaborProfilePageState();
}

class _LaborProfilePageState extends State<LaborProfilePage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
  _controller = YoutubePlayerController.fromVideoId(
  videoId: 'dQw4w9WgXcQ',
  params: const YoutubePlayerParams(
    showControls: true,
    showFullscreenButton: true,
  ),
);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _controller,
      builder: (context, player) {
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
                ElevatedButton(
                  onPressed: _downloadCV,
                  child: const Text('Download CV'),
                ),
                const SizedBox(height: 16),
                // YouTube video player
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black,
                  ),
                  child: player,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadCV() async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required.')),
        );
        return;
      }

      // Load CV from assets
      final byteData = await rootBundle.load('assets/cvs/cv.pdf');
      final buffer = byteData.buffer.asUint8List();

      // Save to Downloads folder
      final filePath = await _saveFile(buffer, 'cv.pdf');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CV saved to $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving CV: $e')),
      );
    }
  }

  Future<String> _saveFile(Uint8List bytes, String fileName) async {
    Directory? dir;

    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
