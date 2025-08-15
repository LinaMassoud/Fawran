import 'dart:io';
import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/providers/nationality_provider.dart';
import 'package:fawran/providers/package_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:hijri/hijri_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) async {
      final payload = details.payload;
      if (payload != null) {
        await OpenFile.open(payload);
      }
    },
  );
}

class _HtmlToPdfScreenState extends ConsumerState<HtmlToPdfScreen> {
  String? pdfPath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndGeneratePdf();

  }

  /// Replace placeholders in the HTML string
  String _replacePlaceholders(String html) {
    String todayHijry ="${ HijriCalendar.now().hDay}/${ HijriCalendar.now().hMonth}/${ HijriCalendar.now().hYear}";


    final selectedProfession = ref.watch(selectedProfessionProvider);
    
final selectedPackage = ref.watch(
        selectedPackageProvider);
      final locationParts = _extractLocationParts(); // get city and area
            final today = getTodayName();
              final selectedNationality = ref.watch(selectedNationalityProvider);
double finalPrice = selectedPackage == null ? 0.0:  selectedPackage.contractAmount + selectedPackage.vatAmount;

    String result = html;
  
      result = result.replaceAll("#CONTRACT_ID#", "99999");
      result = result.replaceAll("#PROFFESSION#", selectedProfession?.positionName??'');
  result = result.replaceAll("#CITY#", locationParts['city'] ?? '');
  result = result.replaceAll("#DISTIRTICT#", locationParts['area'] ?? '');

        result = result.replaceAll("#DAY_AR#", today ?? '');
        result = result.replaceAll("#CREATION_DATE#", getDateInArabic() ?? '');
        result = result.replaceAll("#CREATION_DATE_AR#", todayHijry ?? '');
        result = result.replaceAll("#PACKAGE_NAME#", selectedPackage?.packageName ?? '');
        result = result.replaceAll("#GENDER#", selectedProfession?.positionId == 7  ? 'أنثى':"ذكر");
        result = result.replaceAll("#FINAL_PRICE#", finalPrice.toString() );


    return result;
  }

  String getDateInArabic() {
  // Initialize Arabic locale
  initializeDateFormatting('ar', null);

  final now = DateTime.now();
  
  // Format: Day Name, Day Month Year
  final formatter = DateFormat('EEEE, d MMMM y', 'ar');

  return formatter.format(now);
}

  String getTodayName() {
  final now = DateTime.now();
  const weekdays = [
    'الاثنين',    // DateTime.weekday: 1
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الاحد',
  ];
  return weekdays[now.weekday - 1]; // weekday is 1-based
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


  Future<void> _loadAndGeneratePdf() async {
    try {
      // Load HTML from asset
      String htmlContent = await rootBundle.loadString(widget.htmlAssetPath);

      // Replace placeholders
      htmlContent = _replacePlaceholders(htmlContent);

      // Generate PDF
      final output = await getTemporaryDirectory();
      final file = await FlutterHtmlToPdf.convertFromHtmlContent(
        htmlContent,
        output.path,
        'generated_contract.pdf',
      );

      setState(() {
        pdfPath = file.path;
        isLoading = false;
      });
    } catch (e) {
      print("Error generating PDF: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pdfPath == null
              ? const Center(child: Text('Failed to load PDF'))
              : Column(
                  children: [
                    Expanded(
                      child: PDFView(
                        filePath: pdfPath!,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: true,
                        pageFling: true,
                      ),
                    ),
            Padding(
  padding: const EdgeInsets.all(16.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      ElevatedButton(
        onPressed: () async {
          if (pdfPath != null) {
            await OpenFile.open(pdfPath!);
          }
        },
        child: const Text('Open PDF'),
      ),
      ElevatedButton(
        onPressed: () async {
           if (pdfPath != null) {
      await downloadLocalPdf(pdfPath!); // Use the pdfPath for download
    }
        },
        child: const Text('Download PDF'),
      ),
    ],
  ),
),
                  ],
                ),
    );
  }

  Future<void> _downloadPdf(String pdfPath) async {
  bool granted = await _requestStoragePermission();
  if (!granted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Storage permission denied')),
    );
    return;
  }

  final downloadsDir = await getExternalStorageDirectory();
  final savePath = '${downloadsDir!.path}/generated_contract.pdf';

  await FlutterDownloader.enqueue(
    url: 'file://$pdfPath', // Can be a local file path if you prefix with file://
    savedDir: downloadsDir.path,
    fileName: 'generated_contract.pdf',
    showNotification: true, // show notification in status bar
    openFileFromNotification: true, // tap notification to open file
  );
}

Future<bool> _requestStoragePermission() async {
  if (Platform.isAndroid) {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }
  return true;
}


Future<void> downloadLocalPdf(String pdfPath) async {
  if (Platform.isAndroid) {
    var status = await Permission.storage.request();
    if (!status.isGranted) return;
  }

  final downloadsDir = Directory('/storage/emulated/0/Download'); // Downloads folder
  if (!await downloadsDir.exists()) {
    await downloadsDir.create(recursive: true);
  }

  final fileName = 'generated_contract.pdf';
  final newPath = '${downloadsDir.path}/$fileName';

  final sourceFile = File(pdfPath);
  await sourceFile.copy(newPath);

  // Optional: show a snackbar
  print('File saved to $newPath');
}


}
