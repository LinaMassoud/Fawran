import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({Key? key}) : super(key: key);

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Dropdown values
  Map<String, dynamic>? selectedCity;
  String? selectedSectorType;
  Map<String, dynamic>? selectedCategory;
  Map<String, dynamic>? selectedTicketType;

  // Data lists
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> ticketTypes = [];

  // Loading states
  bool isLoadingCities = true;
  bool isLoadingCategories = false;
  bool isLoadingTicketTypes = false;
  bool isSubmitting = false;

  // Sector type options
  final List<Map<String, String>> sectorTypes = [
    {'value': 'I', 'label': 'Individual'},
    {'value': 'H', 'label': 'Hourly'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      setState(() {
        isLoadingCities = true;
      });

      final fetchedCities = await ApiService.fetchCitiesForTicket();
      setState(() {
        cities = fetchedCities;
        isLoadingCities = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCities = false;
      });
      _showErrorSnackBar('Failed to load cities');
    }
  }

  Future<void> _loadCategories(String sectorType) async {
    try {
      setState(() {
        isLoadingCategories = true;
        selectedCategory = null;
        selectedTicketType = null;
        categories = [];
        ticketTypes = [];
      });

      final fetchedCategories = await ApiService.fetchTicketCategories(sectorType);
      setState(() {
        categories = fetchedCategories;
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCategories = false;
      });
      _showErrorSnackBar('Failed to load ticket categories');
    }
  }

  Future<void> _loadTicketTypes(int categoryId) async {
    try {
      setState(() {
        isLoadingTicketTypes = true;
        selectedTicketType = null;
        ticketTypes = [];
      });

      final fetchedTypes = await ApiService.fetchTicketTypes(categoryId);
      setState(() {
        ticketTypes = fetchedTypes;
        isLoadingTicketTypes = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTicketTypes = false;
      });
      _showErrorSnackBar('Failed to load ticket types');
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCity == null ||
        selectedSectorType == null ||
        selectedCategory == null ||
        selectedTicketType == null) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    try {
      setState(() {
        isSubmitting = true;
      });

      final customerId = await _secureStorage.read(key: 'user_id');
      if (customerId == null) {
        _showErrorSnackBar('User not found. Please login again.');
        return;
      }

      final result = await ApiService.createTicket(
        customerId: customerId,
        cityCode: selectedCity!['city_code']?.toString() ?? 
                  selectedCity!['code']?.toString() ?? '',
        sectorType: selectedSectorType!,
        ticketCategoryId: selectedCategory!['category_id'] ?? 
                         selectedCategory!['id'] ?? 0,
        ticketTypeId: selectedTicketType!['type_id'] ?? 
                     selectedTicketType!['id'] ?? 0,
        details: _detailsController.text.trim(),
      );

      if (result != null) {
        _showSuccessSnackBar('Ticket created successfully');
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        _showErrorSnackBar('Failed to create ticket. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
  backgroundColor: Colors.grey[50],
  appBar: AppBar(
    toolbarHeight: 65,
    backgroundColor: const Color(0xFF10295C),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    ),
    leading: GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
          color: const Color(0xFFFFA200),
          size: 20,
        ),
      ),
    ),
    title: const Text(
      'Create Support Ticket',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFFFA200),
      ),
    ),
    centerTitle: true,
    elevation: 0,
  ),
  body: GestureDetector(
    onTap: () {
      // Dismiss keyboard when tapping anywhere on the screen
      FocusScope.of(context).unfocus();
    },
    child: Form(
    key: _formKey,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Add bottom padding for fixed button
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          
          // City Dropdown
          _buildSectionTitle('City'),
          const SizedBox(height: 8),
          _buildCityDropdown(),
          const SizedBox(height: 24),

          // Sector Type Dropdown
          _buildSectionTitle('Sector Type'),
          const SizedBox(height: 8),
          _buildSectorTypeDropdown(),
          const SizedBox(height: 24),

          // Ticket Category Dropdown
          _buildSectionTitle('Ticket Category'),
          const SizedBox(height: 8),
          _buildCategoryDropdown(),
          const SizedBox(height: 24),

          // Ticket Type Dropdown
          _buildSectionTitle('Ticket Type'),
          const SizedBox(height: 8),
          _buildTicketTypeDropdown(),
          const SizedBox(height: 24),

          _buildDetailsField(),
          const SizedBox(height: 24),

          // Upload Attach Button
          _buildUploadButton(),
          const SizedBox(height: 20),
        ],
      ),
    ),
  ),
  ),
  bottomNavigationBar: _buildFixedBottomSendButton(),
);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF091735),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<Map<String, dynamic>>(
        value: selectedCity,
        decoration: const InputDecoration(
          hintText: 'Choose City',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        items: isLoadingCities
          ? []
          : cities.map((city) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: city,
                child: Expanded(
                  child: Text(
                    city['city_name']?.toString() ?? 
                    city['name']?.toString() ?? 'Unknown',
                    style: const TextStyle(color: Color(0xFF091735)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }).toList(),
        onChanged: isLoadingCities
            ? null
            : (value) {
                setState(() {
                  selectedCity = value;
                });
              },
        validator: (value) {
          if (value == null) {
            return 'Please select a city';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSectorTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedSectorType,
        decoration: const InputDecoration(
          hintText: 'Choose Sector',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        items: sectorTypes.map((sector) {
          return DropdownMenuItem<String>(
            value: sector['value'],
            child: Text(
              sector['label']!,
              style: const TextStyle(color: Color(0xFF091735)),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedSectorType = value;
            selectedCategory = null;
            selectedTicketType = null;
          });
          if (value != null) {
            _loadCategories(value);
          }
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a sector type';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<Map<String, dynamic>>(
        value: selectedCategory,
        decoration: const InputDecoration(
          hintText: 'Choose Category',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        items: isLoadingCategories
          ? []
          : categories.map((category) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: category,
                child: Expanded(
                  child: Text(
                    category['category_name']?.toString() ?? 
                    category['name']?.toString() ?? 'Unknown',
                    style: const TextStyle(color: Color(0xFF091735)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }).toList(),
        onChanged: isLoadingCategories
            ? null
            : (value) {
                setState(() {
                  selectedCategory = value;
                  selectedTicketType = null;
                });
                if (value != null) {
                  final categoryId = value['category_id'] ?? value['id'];
                  if (categoryId != null) {
                    _loadTicketTypes(categoryId);
                  }
                }
              },
        validator: (value) {
          if (value == null) {
            return 'Please select a category';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTicketTypeDropdown() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: DropdownButtonFormField<Map<String, dynamic>>(
      value: selectedTicketType,
      decoration: const InputDecoration(
        hintText: 'Choose Type',
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      isExpanded: true, // Add this line to prevent overflow
      items: isLoadingTicketTypes
        ? []
        : ticketTypes.map((type) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: type,
              child: Text(
                type['type_name']?.toString() ?? 
                type['name']?.toString() ?? 'Unknown',
                style: const TextStyle(color: Color(0xFF091735)),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),

      onChanged: isLoadingTicketTypes
          ? null
          : (value) {
              setState(() {
                selectedTicketType = value;
              });
            },
      validator: (value) {
        if (value == null) {
          return 'Please select a ticket type';
        }
        return null;
      },
    ),
  );
}

  Widget _buildDetailsField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _detailsController,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'Ticket Details',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter ticket details';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF4A6FA5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            // TODO: Implement file upload functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Upload functionality to be implemented')),
            );
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Upload Attach',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.upload,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildFixedBottomSendButton() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF1E49A0).withOpacity(0.15),
          blurRadius: 20,
          spreadRadius: 2,
          offset: Offset(0, -5),
        ),
        BoxShadow(
          color: Color(0xFF1E49A0).withOpacity(0.08),
          blurRadius: 40,
          spreadRadius: 5,
          offset: Offset(0, -10),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 15),
        child: Container(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _submitTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: isSubmitting 
                  ? Colors.grey[400]
                  : const Color(0xFF10295C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: isSubmitting ? 0 : 2,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Send',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}
}