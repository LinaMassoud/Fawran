import 'package:flutter/material.dart';
import 'cleaning_service_screen.dart'; // Import to access PackageModel
import 'date_selection_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final PackageModel package;
  final String selectedAddress;
  final String selectedAddressId;
  final String selectedAddressFullAddress;

  const ServiceDetailsScreen({
    Key? key,
    required this.package,
    required this.selectedAddress,
    required this.selectedAddressId,
    required this.selectedAddressFullAddress,
  }) : super(key: key);

  @override
  _ServiceDetailsScreenState createState() => _ServiceDetailsScreenState();

  // Static method to show as overlay
  static void showAsOverlay(
    BuildContext context, {
    required PackageModel package,
    required String selectedAddress,
    required String selectedAddressId,
    required String selectedAddressFullAddress,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceDetailsScreen(
        package: package,
        selectedAddress: selectedAddress,
        selectedAddressId: selectedAddressId,
        selectedAddressFullAddress: selectedAddressFullAddress,
      ),
    );
  }
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  String selectedNationality = 'East Asia';
  late int workerCount;
  late String contractDuration;
  String selectedTime = 'Morning';
  late String visitDuration;
  late String visitsPerWeek;

  List<String> nationalities = ['East Asia', 'South Asia', 'Africa', 'Europe'];
  List<String> times = ['Morning', 'Afternoon', 'Evening'];
  List<String> durations = ['2 hours', '3 hours', '4 hours', '5 hours', '6 hours'];
  List<String> contractDurations = ['1 week', '2 weeks', '1 month', '3 months', '6 months'];
  List<String> visitFrequencies = ['1 visit weekly', '2 visits weekly', '3 visits weekly'];

  @override
  void initState() {
    super.initState();
    
    // Initialize values based on package data
    workerCount = widget.package.noOfEmployee;
    contractDuration = '${widget.package.noOfMonth} month${widget.package.noOfMonth > 1 ? 's' : ''}';
    visitDuration = '${widget.package.duration} hours';
    visitsPerWeek = '${widget.package.visitsWeekly} visit${widget.package.visitsWeekly > 1 ? 's' : ''} weekly';
    
    // Set nationality based on group code or service shift
    selectedNationality = widget.package.groupCode == '2' ? 'East Asia' : 'South Asia';
    
    // Set time based on service shift
    selectedTime = _getTimeFromShift(widget.package.serviceShift);
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start the animation
    _animationController.forward();
  }

  String _getTimeFromShift(String shift) {
    switch (shift) {
      case '1':
        return 'Morning';
      case '2':
        return 'Afternoon';
      case '3':
        return 'Evening';
      default:
        return 'Morning';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeOverlay() async {
    await _animationController.reverse();
    Navigator.pop(context);
  }

  void _selectDate() async {
  final selectedDates = await Navigator.push<List<DateTime>>(
    context,
    MaterialPageRoute(
      builder: (context) => DateSelectionScreen(
        package: widget.package,
        selectedAddress: widget.selectedAddress,
        selectedAddressId: widget.selectedAddressId,
        selectedAddressFullAddress: widget.selectedAddressFullAddress,
      ),
    ),
  );
  
  if (selectedDates != null && selectedDates.isNotEmpty) {
    // Handle the selected dates
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${selectedDates.length} date(s) successfully'),
        backgroundColor: Colors.green,
      ),
    );
    
    // You can store the selected dates in the state if needed
    // setState(() {
    //   this.selectedDates = selectedDates;
    // });
  }
}

  void _proceedToBooking() {
    // Create booking data object
    final bookingData = {
      'package': widget.package,
      'selectedAddress': widget.selectedAddress,
      'selectedAddressId': widget.selectedAddressId,
      'selectedAddressFullAddress': widget.selectedAddressFullAddress,
      'nationality': selectedNationality,
      'workerCount': workerCount,
      'contractDuration': contractDuration,
      'selectedTime': selectedTime,
      'visitDuration': visitDuration,
      'visitsPerWeek': visitsPerWeek,
    };

    // Navigate to booking confirmation or payment screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Proceeding to booking confirmation...'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Here you would typically navigate to the next screen or make API call
    print('Booking Data: $bookingData');
  }

  Widget _buildDropdownField(String label, String value, List<String> options, Function(String) onChanged, {bool isEnabled = true}) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!, 
          width: 1.5
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (isEnabled)
            PopupMenuButton<String>(
              onSelected: onChanged,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              itemBuilder: (context) => options.map((option) => 
                PopupMenuItem<String>(
                  value: option,
                  child: Text(option),
                )
              ).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkerCountField() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Number of Workers',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '$workerCount Worker${workerCount > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (workerCount > 1) {
                    setState(() {
                      workerCount--;
                    });
                  }
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.remove, size: 18, color: Colors.grey[600]),
                ),
              ),
              SizedBox(width: 15),
              Text(
                '$workerCount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 15),
              GestureDetector(
                onTap: () {
                  setState(() {
                    workerCount++;
                  });
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.add, size: 18, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Semi-transparent background
              GestureDetector(
                onTap: _closeOverlay,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              
              // Close button positioned outside the white modal
              Positioned(
                top: 50,
                right: 20,
                child: GestureDetector(
                  onTap: _closeOverlay,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Sliding content from bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header Section
                        Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Header Image and Title
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF20B2AA), Color(0xFF4682B4)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Background pattern or image would go here
                                    Positioned(
                                      left: 20,
                                      top: 15,
                                      child: Text(
                                        '100% Guarantee',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // Cleaning person illustration would be positioned here
                                    Positioned(
                                      right: 20,
                                      bottom: 10,
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.cleaning_services,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 20),
                              
                              // Service Title and Rating
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '1 weekly visit:Cleaning Visit',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.star, color: Colors.amber, size: 20),
                                            SizedBox(width: 5),
                                            Text(
                                              '4.83 (34K reviews)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Get SAR 225 off',
                                            style: TextStyle(
                                              color: Colors.green[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Form Section
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Nationality - looks like dropdown but not functional
                                  _buildDropdownField(
                                    'Nationality', 
                                    selectedNationality,
                                    nationalities,
                                    (value) {
                                      // Do nothing - this field is read-only
                                    },
                                    isEnabled: false
                                  ),
                                  
                                  _buildWorkerCountField(),
                                  
                                  _buildDropdownField('Contract Duration', contractDuration, contractDurations, (value) {
                                    setState(() {
                                      contractDuration = value;
                                    });
                                  }),
                                  
                                  // Time - looks like dropdown but not functional
                                  _buildDropdownField(
                                    'Time', 
                                    selectedTime,
                                    times,
                                    (value) {
                                      // Do nothing - this field is read-only
                                    },
                                    isEnabled: false
                                  ),
                                  
                                  // Duration of visit - looks like dropdown but not functional
                                  _buildDropdownField(
                                    'Duration of visit', 
                                    visitDuration,
                                    durations,
                                    (value) {
                                      // Do nothing - this field is read-only
                                    },
                                    isEnabled: false
                                  ),
                                  
                                  _buildDropdownField('Visits week number', visitsPerWeek, visitFrequencies, (value) {
                                    setState(() {
                                      visitsPerWeek = value;
                                    });
                                  }),
                                  
                                  SizedBox(height: 20),
                                  
                                  // Select Date Button
                                  GestureDetector(
                                    onTap: _selectDate,
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 18),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Colors.grey[300]!, width: 1.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Select date',
                                            style: TextStyle(
                                              color: Colors.purple,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: Colors.purple,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: 100), // Bottom padding for the fixed bottom section
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}