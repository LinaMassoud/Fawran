import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/providers/nationality_provider.dart';
import 'package:fawran/providers/package_provider.dart';
import 'package:fawran/screens/bookings.dart';
import 'package:fawran/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

// Syncfusion
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class HtmlToPdfScreen extends ConsumerStatefulWidget {
  final String title;
  final String htmlAssetPath;

  const HtmlToPdfScreen({
    Key? key,
    required this.title,
    required this.htmlAssetPath,
  }) : super(key: key);

  @override
  ConsumerState<HtmlToPdfScreen> createState() => _HtmlToPdfScreenState();
}

class _HtmlToPdfScreenState extends ConsumerState<HtmlToPdfScreen> {
  String? pdfPath;
  bool isLoading = true;
  final _storage = const FlutterSecureStorage();
  String? contractId;
  bool _hasSigned = false;
  File? _signedPdfFile;
  final GlobalKey<SfSignaturePadState> signatureKey = GlobalKey();
  Uint8List? _signatureBytes;
  Map<String, dynamic>? args;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      contractId = args?['contract_Id'] as String;
      _loadAndGeneratePdf(contractId);
    });
  }

  Future<String> _replacePlaceholders(String html, String? contractId) async {
    String todayHijry =
        "${HijriCalendar.now().hDay}/${HijriCalendar.now().hMonth}/${HijriCalendar.now().hYear}";
    String userId = await _storage.read(key: 'user_id') ?? '';
    String nationalId = await _storage.read(key: 'national_id') ?? '';
    String lastName = await _storage.read(key: 'last_name') ?? '';
    String middleName = await _storage.read(key: 'middle_name') ?? '';
    String firstName = await _storage.read(key: 'first_name') ?? '';

    final selectedProfession = ref.watch(selectedProfessionProvider);
    final selectedPackage = ref.watch(selectedPackageProvider);
    final locationParts = _extractLocationParts();
    final today = getTodayName();
    final selectedNationality = ref.watch(selectedNationalityProvider);

    double finalPrice = selectedPackage == null
        ? 0.0
        : selectedPackage.contractAmount + selectedPackage.vatAmount;

    final email = await _storage.read(key: 'email') ?? '';
    String result = html;

    result = result.replaceAll("#CONTRACT_ID#", contractId ?? '');
    result =
        result.replaceAll("#CLIENT_NAME#", "$firstName $middleName $lastName");
    result = result.replaceAll("#ID_NUMBER#", nationalId);
    result = result.replaceAll(
        "#PROFFESSION#", selectedProfession?.positionName ?? '');
    result = result.replaceAll("#CITY#", locationParts['city'] ?? '');
    result = result.replaceAll("#DISTIRTICT#", locationParts['area'] ?? '');
    result = result.replaceAll("#DAY_AR#", today ?? '');
    result = result.replaceAll("#CREATION_DATE#", getDateInArabic() ?? '');
    result = result.replaceAll("#CREATION_DATE_AR#", todayHijry ?? '');
    result =
        result.replaceAll("#PACKAGE_NAME#", selectedPackage?.packageName ?? '');
    result = result.replaceAll(
        "#GENDER#", selectedProfession?.positionId == 7 ? 'أنثى' : "ذكر");
    result = result.replaceAll("#FINAL_PRICE#", finalPrice.toString());
    result = result.replaceAll("#EMAIL#", email);
    result =
        result.replaceAll("#NATIONALITY#", selectedNationality?.name ?? '');
    result = result.replaceAll(
        "#PRICE_BEFORE_VAT#", selectedPackage?.contractAmount.toString() ?? '');
    result = result.replaceAll(
        "#VAT_AMOUNT#", selectedPackage?.vatAmount.toString() ?? '');
    result = result.replaceAll(
        "#PERIOD_DAYS#", selectedPackage?.contractDays.toString() ?? '');

    ref.read(selectedPackageProvider.notifier).state = null;
    return result;
  }

  String getDateInArabic() {
    initializeDateFormatting('ar', null);
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d MMMM y', 'ar');
    return formatter.format(now);
  }

  String getTodayName() {
    final now = DateTime.now();
    const weekdays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الاحد',
    ];
    return weekdays[now.weekday - 1];
  }

  Map<String, String> _extractLocationParts() {
    final currentSelectedAddress = ref.read(selectedAddressProvider);
    final cardText = currentSelectedAddress?.cardText;

    String city = '';
    String area = '';

    if (cardText == null || cardText.isEmpty) {
      return {'city': '', 'area': ''};
    }

    try {
      List<String> parts = cardText.split('-');
      if (parts.length >= 2) {
        city = parts[0].trim();
        area = parts[1].trim();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        city = parts[0].trim();
      }
    } catch (e) {
      print('Error parsing address: $e');
    }

    return {'city': city, 'area': area};
  }

  Future<void> _loadAndGeneratePdf(String? contractId) async {
    try {
      String htmlContent = await rootBundle.loadString(widget.htmlAssetPath);
      htmlContent = await _replacePlaceholders(htmlContent, contractId);

      final output = await getTemporaryDirectory();
      final file = await FlutterHtmlToPdf.convertFromHtmlContent(
        htmlContent,
        output.path,
        'generated_contract.pdf',
      );

      print(
          "PDF path: ${file.path}, exists: ${await File(file.path).exists()}");

      setState(() {
        pdfPath = file.path;
        isLoading = false;
      });
    } catch (e) {
      print("Error generating PDF: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveAndUploadPdf() async {
    if (pdfPath == null) return;

    if (signatureKey.currentState != null) {
      final data = await signatureKey.currentState!.toImage(pixelRatio: 3.0);
      final bytes = await data.toByteData(format: ui.ImageByteFormat.png);
      _signatureBytes = bytes!.buffer.asUint8List();
    }

    final pdfDoc = PdfDocument(inputBytes: File(pdfPath!).readAsBytesSync());
    final page = pdfDoc.pages[pdfDoc.pages.count - 1];

    if (_signatureBytes != null) {
      page.graphics.drawImage(
        PdfBitmap(_signatureBytes!),
        const Rect.fromLTWH(100, 600, 200, 80),
      );
    }

    final signedBytes = pdfDoc.saveSync();
    pdfDoc.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final signedPath = "${dir.path}/signed_contract.pdf";
    await File(signedPath).writeAsBytes(signedBytes);

    setState(() {
      pdfPath = signedPath;
      _signatureBytes = null;
    });

    await _uploadPdf(signedPath);
  }

  Future<void> _uploadPdf(String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("https://your-api.com/upload"),
      );
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PDF uploaded successfully")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Upload failed")));
      }
    } catch (e) {
      print("Upload error: $e");
    }
  }

  Future<void> _saveAndShowPdf() async {
    if (pdfPath == null) return;

    // Capture the signature
    if (signatureKey.currentState != null) {
      final data = await signatureKey.currentState!.toImage(pixelRatio: 3.0);
      final bytes = await data.toByteData(format: ui.ImageByteFormat.png);
      _signatureBytes = bytes!.buffer.asUint8List();
    }

    if (_signatureBytes == null) return; // Nothing drawn

    // Load PDF and add signature
    final pdfDoc = PdfDocument(inputBytes: File(pdfPath!).readAsBytesSync());
    final page = pdfDoc.pages[pdfDoc.pages.count - 1];

    final pageSize = page.getClientSize();
    final double sigWidth = 100;
    final double sigHeight = 50;
    final double x = 150; // adjust to align perfectly
    final double y = pageSize.height - 490;

    page.graphics.drawImage(
      PdfBitmap(_signatureBytes!),
      Rect.fromLTWH(x, y, sigWidth, sigHeight),
    );

    // Save the updated PDF
    final signedBytes = pdfDoc.saveSync();
    pdfDoc.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final signedPath = "${dir.path}/signed_contract.pdf";
    final signedFile = File(signedPath);
    await signedFile.writeAsBytes(signedBytes);

    // Store the file in state for later upload
    setState(() {
      _signedPdfFile = signedFile;
      pdfPath = signedPath; // refresh viewer
      _signatureBytes = null;
      _hasSigned = true;
    });

    // Clear signature pad
    signatureKey.currentState?.clear();
  }

  Future<void> uploadSignedPdf() async {
    if (_signedPdfFile == null) return;
    String userId = await _storage.read(key: 'user_id') ?? '';
    final bytes = await _signedPdfFile!.readAsBytes();
    final platformFile = PlatformFile(
      name: 'signed_contract.pdf',
      path: _signedPdfFile!.path,
      bytes: bytes,
      size: bytes.length,
    );

    final response = await ApiService.uploadFile(
      file: platformFile,
      fileName: 'signed_contract${contractId}${DateTime.now()}.pdf',
      type: 'contract',
      userId: userId,
    );

    if (response != null && response['file_path'] != null) {
      final attachfileResponse = await ApiService.attachContract(
          contractId: contractId, filePath: response['file_path']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushNamed(context, '/bookings');
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload PDF.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pdfPath == null
              ? const Center(child: Text('Failed to load PDF'))
              : Column(
                  children: [
                    Expanded(
                      child: SfPdfViewer.file(
                        File(pdfPath!),
                        onDocumentLoadFailed: (details) {
                          print("PDF load failed: ${details.error}");
                        },
                      ),
                    ),
                    // Signature pad container
                    Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Stack(
                        children: [
                          SfSignaturePad(
                            key: signatureKey,
                            backgroundColor: Colors.transparent,
                            strokeColor: Colors.black,
                            minimumStrokeWidth: 1,
                            maximumStrokeWidth: 3,
                            onDrawEnd: () {
                              setState(() {});
                            },
                          ),

                          // Placeholder label
                          if (_signatureBytes == null)
                            const Center(
                              child: Text(
                                "Sign here",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width: 140, // adjust width as needed
                                child: ElevatedButton(
                                  onPressed: _saveAndShowPdf,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    loc.savesign,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                                  onPressed:
                                      _hasSigned ? uploadSignedPdf : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _hasSigned ? Colors.green : Colors.grey,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    loc.completecontract,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12), // space between rows
                          SizedBox(
                            width: 140,
                            child: ElevatedButton(
                              onPressed: () {
                                signatureKey.currentState?.clear();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                loc.clear,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
    );
  }
}
