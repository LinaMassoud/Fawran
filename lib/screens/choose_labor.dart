import 'package:fawran/screens/service_provider.dart';
import 'package:flutter/material.dart';




class PermanentPrivateDriverScreen extends StatefulWidget {
  final String header;

  const PermanentPrivateDriverScreen({super.key, required this.header});
  @override
  _PermanentPrivateDriverScreenState createState() =>
      _PermanentPrivateDriverScreenState();
}

class _PermanentPrivateDriverScreenState
    extends State<PermanentPrivateDriverScreen> {
  int? selectedDriverIndex;

  final List<Map<String, dynamic>> drivers = [
    {
      'name': 'Benard Christine',
      'role': 'Private Driver',
      'age': 37,
      'religion': 'Muslim',
      'country': 'Bangladesh'
    },
    {
      'name': 'Zaina Nabbanja',
      'role': 'Private Driver',
      'age': 28,
      'religion': 'Muslim',
      'country': 'Bangladesh'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.header),
        backgroundColor: Colors.blue[900],
        leading: BackButton(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: const [
                Text('2', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                Text('Choose Labor',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(driver['name'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Radio<int>(
                          value: index,
                          groupValue: selectedDriverIndex,
                          onChanged: (value) {
                            setState(() {
                              selectedDriverIndex = value;
                            });
                          },
                        )
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver['role']),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Religion\n${driver['religion']}'),
                            Text('Country\n${driver['country']}'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('Show More', style: TextStyle(color: Colors.blue))
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: selectedDriverIndex != null
                  ? () {
                      final selectedDriver = drivers[selectedDriverIndex!];
                      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      //   content: Text(
                      //       'Order completed for ${selectedDriver['name']}'),
                      // ));

                             Navigator.push(
            context,
           
        MaterialPageRoute(
                              builder: (context) =>  ServiceProvidersScreen(header:widget.header),
                            ),
          );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor:
                    selectedDriverIndex != null ? Colors.blue[900] : Colors.grey,
              ),
              child: Text('COMPLETE ORDER'),
            ),
          )
        ],
      ),
    );
  }
}
