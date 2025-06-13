import 'package:fawran/providers/labour_provider.dart';
import 'package:fawran/screens/service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermanentPrivateDriverScreen extends ConsumerStatefulWidget {
  final String header;

  const PermanentPrivateDriverScreen({super.key, required this.header});

  @override
  _PermanentPrivateDriverScreenState createState() =>
      _PermanentPrivateDriverScreenState();
}

class _PermanentPrivateDriverScreenState
    extends ConsumerState<PermanentPrivateDriverScreen> {
  int? selectedDriverId;

  @override
  Widget build(BuildContext context) {
    final laborersAsync = ref.watch(laborersProvider);

    Widget content;

    if (laborersAsync.isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (laborersAsync.hasError) {
      content = Center(
        child: Text('Failed to load laborers: ${laborersAsync.error}'),
      );
    } else {
      final drivers = laborersAsync.value ?? [];

      content = Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: const [
                Text('2', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                Text(
                  'Choose Labor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                final int personId = driver.personId;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            driver.employeeName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Radio<int>(
                          value: personId,
                          groupValue: selectedDriverId,
                          onChanged: (int? value) {
                            setState(() {
                              selectedDriverId = value;
                            });
                            ref.read(selectedLaborerProvider.notifier).state =
                                driver;
                          },
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.positionName),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child:
                                  Text('Arabic Name\n${driver.arabicName}'),
                            ),
                            Flexible(
                              child:
                                  Text('Nationality\n${driver.nationality}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Show More',
                            style: TextStyle(color: Colors.blue)),
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
              onPressed: selectedDriverId != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceProvidersScreen(
                            header: widget.header,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor:
                    selectedDriverId != null ? Colors.blue[900] : Colors.grey,
              ),
              child: const Text('COMPLETE ORDER'),
            ),
          )
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.header),
        backgroundColor: Colors.blue[900],
        leading: const BackButton(),
      ),
      body: content,
    );
  }
}
