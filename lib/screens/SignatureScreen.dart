import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class SignatureScreen extends StatefulWidget {
  final String pdfPath; // Pass the generated contract here
  const SignatureScreen({Key? key, required this.pdfPath}) : super(key: key);

  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();

  Future<void> _saveSignature() async {
    // Get image bytes from signature pad
    final data = await _signaturePadKey.currentState!.toImage(pixelRatio: 3.0);
    final bytes = await data.toByteData(format: ImageByteFormat.png);
    final Uint8List signatureBytes = bytes!.buffer.asUint8List();

    // Open PDF document
    final pdfDoc = PdfDocument(inputBytes: File(widget.pdfPath).readAsBytesSync());

    // Get first page
    final page = pdfDoc.pages[0];

    // Draw signature image on page
    page.graphics.drawImage(
      PdfBitmap(signatureBytes),
      const Rect.fromLTWH(100, 600, 150, 80), // adjust position & size
    );

    // Save modified PDF
    final signedBytes = pdfDoc.saveSync();
    pdfDoc.dispose();

    final signedPath = "${widget.pdfPath}_signed.pdf";
    final signedFile = File(signedPath)..writeAsBytesSync(signedBytes);

    Navigator.pop(context, signedFile.path); // return signed file path
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Contract")),
      body: Column(
        children: [
          Expanded(
            child: SfSignaturePad(
              key: _signaturePadKey,
              backgroundColor: Colors.grey[200]!,
              strokeColor: Colors.black,
              minimumStrokeWidth: 1.0,
              maximumStrokeWidth: 3.0,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _signaturePadKey.currentState!.clear(),
                child: const Text("Clear"),
              ),
              ElevatedButton(
                onPressed: _saveSignature,
                child: const Text("Save Signature"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
