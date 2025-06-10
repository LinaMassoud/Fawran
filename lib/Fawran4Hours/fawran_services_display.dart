import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cleaning_service_screen.dart'; 

class FawranServicesScreen extends StatefulWidget {
  final int selectedPositionId;
  final String selectedPositionName;

  const FawranServicesScreen({
    Key? key,
    required this.selectedPositionId,
    required this.selectedPositionName,
  }) : super(key: key);

  @override
  _FawranServicesScreenState createState() => _FawranServicesScreenState();
}

class _FawranServicesScreenState extends State<FawranServicesScreen> {
  List<Service> services = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.20.10.114:8080/ords/emdad/fawran/home/professions'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Find the selected position and extract its services
        for (var position in data) {
          if (position['position_id'] == widget.selectedPositionId) {
            final List<dynamic> servicesList = position['services'];
            services = servicesList.map((service) => Service.fromJson(service)).toList();
            break;
          }
        }
        
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load services';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Color _getServiceColor(String serviceName) {
    if (serviceName.toLowerCase().contains('4 hours') || 
        serviceName.toLowerCase().contains('fawran 4')) {
      return const Color(0xFF4CAF50); // Green for 4 hours
    } else if (serviceName.toLowerCase().contains('8 hours') || 
               serviceName.toLowerCase().contains('fawran 8')) {
      return const Color(0xFF2196F3); // Blue for 8 hours
    } else if (serviceName.toLowerCase().contains('maintenance')) {
      return const Color(0xFFFF9800); // Orange for maintenance
    } else if (serviceName.toLowerCase().contains('permanent')) {
      return const Color(0xFF9C27B0); // Purple for permanent
    }
    return const Color(0xFF607D8B); // Default gray
  }

  IconData _getServiceIcon(String serviceName) {
    if (serviceName.toLowerCase().contains('4 hours') || 
        serviceName.toLowerCase().contains('fawran 4')) {
      return Icons.schedule;
    } else if (serviceName.toLowerCase().contains('8 hours') || 
               serviceName.toLowerCase().contains('fawran 8')) {
      return Icons.access_time;
    } else if (serviceName.toLowerCase().contains('maintenance')) {
      return Icons.build;
    } else if (serviceName.toLowerCase().contains('permanent')) {
      return Icons.work;
    }
    return Icons.room_service;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00BCD4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Fawran services',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchServices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF00BCD4),
                      padding: const EdgeInsets.only(bottom: 32),
                      child: const Text(
                        'Choose the service',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      child: services.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No services available for ${widget.selectedPositionName}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ListView.builder(
                                itemCount: services.length,
                                itemBuilder: (context, index) {
                                  final service = services[index];
                                  final serviceColor = _getServiceColor(service.name);
                                  final serviceIcon = _getServiceIcon(service.name);
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Material(
                                      borderRadius: BorderRadius.circular(16),
                                      elevation: 2,
                                      shadowColor: Colors.black12,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                        // Navigate to CleaningServiceScreen with the selected service
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CleaningServiceScreen(
                                              professionId: widget.selectedPositionId, // Use the selected position ID
                                              serviceId: service.id, // Use the selected service ID
                                              serviceType: service.name, // Pass the service name
                                              serviceCode: '', // You can add serviceCode mapping if needed
                                            ),
                                          ),
                                        );
                                      },
                                        child: Container(
                                          height: 120,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                serviceColor.withOpacity(0.8),
                                                serviceColor,
                                              ],
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              // Background pattern
                                              Positioned(
                                                right: -20,
                                                top: -20,
                                                child: Icon(
                                                  serviceIcon,
                                                  size: 80,
                                                  color: Colors.white.withOpacity(0.1),
                                                ),
                                              ),
                                              // Content
                                              Padding(
                                                padding: const EdgeInsets.all(20),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          serviceIcon,
                                                          color: Colors.white,
                                                          size: 24,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Text(
                                                            service.name,
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 22,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '${widget.selectedPositionName} Services',
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.9),
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Arrow indicator
                                              Positioned(
                                                right: 16,
                                                top: 0,
                                                bottom: 0,
                                                child: Center(
                                                  child: Icon(
                                                    Icons.arrow_forward_ios,
                                                    color: Colors.white.withOpacity(0.7),
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class Service {
  final int id;
  final String name;

  Service({required this.id, required this.name});

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'],
    );
  }
}
