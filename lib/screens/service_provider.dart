import 'package:fawran/screens/choose_labor.dart';
import 'package:fawran/screens/packages.dart';
import 'package:flutter/material.dart';

class ServiceProvidersScreen extends StatefulWidget {
  final String header;

  const ServiceProvidersScreen({super.key, required this.header});


  @override
  _ServiceProvidersScreenState createState() => _ServiceProvidersScreenState();
}

class _ServiceProvidersScreenState extends State<ServiceProvidersScreen> {
  final Color headerColor = Color(0xFF112A5C); // Dark blue
  String? selectedNationality;

  final List<String> nationalities = [
    'Indian',
    'Filipino',
    'Bangladeshi',
    'Pakistani',
    'Nepali',
  ];
  

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: statusBarHeight + 100,
            padding: EdgeInsets.only(top: statusBarHeight),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    widget.header,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          // Step Title and Progress
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Service Providers", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("Next - Package", style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(
                        value: 0.4,
                        strokeWidth: 4,
                        color: Colors.green,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    Text("2 of 5", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          // Form Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 4),
                Text("Nationality", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  hint: Text("Please select your prefered nationality"),
                  value: selectedNationality,
                  onChanged: (value) {
                    setState(() {
                      selectedNationality = value;
                    });
                  },
                  items: nationalities
                      .map((nationality) => DropdownMenuItem(
                            value: nationality,
                            child: Text(nationality),
                          ))
                      .toList(),
                ),
                SizedBox(height: 24),

                // Choose Labor Button
                Text("2", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 4),
                Text("Choose Labor", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Open labor selection logic here

                      Navigator.push(
            context,
           
        MaterialPageRoute(
                              builder: (context) =>  PermanentPrivateDriverScreen(header:widget.header),
                            ),
          );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: headerColor,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Select Labor",
                    style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          Spacer(),

          // Bottom Navigation Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF112A5C),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Back", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to next screen
                              Navigator.push(
            context,
           
        MaterialPageRoute(
                              builder: (context) =>  PackageSelectionScreen(header:widget.header),
                            ),
          );
                      
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: headerColor,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Next", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
