import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  String? uploadedFilePath;
String? uploadedFileName;
bool isUploadingFile = false;

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
      fileName: uploadedFilePath ?? "", // Pass the uploaded file path
    );

    if (result != null) {
      _showSuccessSnackBar(result['message'] ?? 'Ticket created successfully');
      Navigator.pop(context, true);
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

  Future<void> _pickAndUploadFile() async {
  try {
    setState(() {
      isUploadingFile = true;
    });

    // Pick file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final fileName = file.name;
      final fileExtension = path.extension(fileName).toLowerCase();
      
      // Determine file type
      String fileType;
      if (['.jpg', '.jpeg', '.png'].contains(fileExtension)) {
        fileType = 'image';
      } else if (fileExtension == '.pdf') {
        fileType = 'document';
      } else {
        _showErrorSnackBar('Unsupported file type. Please select JPG, PNG, or PDF files.');
        return;
      }

      // Get user ID
      final userId = await _secureStorage.read(key: 'user_id');
      if (userId == null) {
        _showErrorSnackBar('User not found. Please login again.');
        return;
      }

      // Upload file
      final uploadResponse = await ApiService.uploadFile(
        file: file,
        fileName: fileName,
        type: fileType,
        userId: userId,
      );

      if (uploadResponse != null) {
        setState(() {
          uploadedFilePath = uploadResponse['file_path'] ?? uploadResponse['path'];
          uploadedFileName = fileName;
        });
        _showSuccessSnackBar(uploadResponse['message'] ?? 'File uploaded successfully');
      } else {
        _showErrorSnackBar('Failed to upload file. Please try again.');
      }
    }
  } catch (e) {
    _showErrorSnackBar('Error selecting file. Please try again.');
    print('Error picking/uploading file: $e');
  } finally {
    setState(() {
      isUploadingFile = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isArabic = currentLocale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
               Icons.arrow_back_ios,
                color: const Color(0xFFFFA200),
                size: 20,
              ),
            ),
          ),
          title: Text(
            loc.createSupportTicket, // Replace hardcoded text
            style: const TextStyle(
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
            FocusScope.of(context).unfocus();
          },
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  
                  // City Dropdown
                  _buildSectionTitle(loc.city, isArabic),
                  const SizedBox(height: 8),
                  _buildCityDropdown(loc, isArabic),
                  const SizedBox(height: 24),

                  // Sector Type Dropdown
                  _buildSectionTitle(loc.sectorType, isArabic),
                  const SizedBox(height: 8),
                  _buildSectorTypeDropdown(loc, isArabic),
                  const SizedBox(height: 24),

                  // Ticket Category Dropdown
                  _buildSectionTitle(loc.ticketCategory, isArabic),
                  const SizedBox(height: 8),
                  _buildCategoryDropdown(loc, isArabic),
                  const SizedBox(height: 24),

                  // Ticket Type Dropdown
                  _buildSectionTitle(loc.ticketType, isArabic),
                  const SizedBox(height: 8),
                  _buildTicketTypeDropdown(loc, isArabic),
                  const SizedBox(height: 24),

                  _buildDetailsField(loc, isArabic),
                  const SizedBox(height: 24),

                  // Upload Attach Button
                  _buildUploadButton(loc, isArabic),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildFixedBottomSendButton(loc, isArabic),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isArabic) {
    return Align(
      alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF091735),
        ),
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      ),
    );
  }

  Widget _buildCityDropdown(AppLocalizations loc, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<Map<String, dynamic>>(
        value: selectedCity,
        decoration: InputDecoration(
          hintText: loc.chooseCity,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
        isExpanded: true,
        items: isLoadingCities
          ? []
          : cities.map((city) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: city,
                child: Text(
                  city['city_name']?.toString() ?? 
                  city['name']?.toString() ?? loc.unknown,
                  style: const TextStyle(color: Color(0xFF091735)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
            return loc.pleaseSelectCity;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSectorTypeDropdown(AppLocalizations loc, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedSectorType,
        decoration: InputDecoration(
          hintText: loc.chooseSector,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
        items: [
          DropdownMenuItem<String>(
            value: 'I',
            child: Text(
              loc.individual,
              style: const TextStyle(color: Color(0xFF091735)),
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
          DropdownMenuItem<String>(
            value: 'H',
            child: Text(
              loc.hourly,
              style: const TextStyle(color: Color(0xFF091735)),
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ],
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
            return loc.pleaseSelectSectorType;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryDropdown(AppLocalizations loc, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<Map<String, dynamic>>(
        value: selectedCategory,
        decoration: InputDecoration(
          hintText: loc.chooseCategory,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
        isExpanded: true,
        items: isLoadingCategories
          ? []
          : categories.map((category) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: category,
                child: Text(
                  category['category_name']?.toString() ?? 
                  category['name']?.toString() ?? loc.unknown,
                  style: const TextStyle(color: Color(0xFF091735)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
            return loc.pleaseSelectCategory;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTicketTypeDropdown(AppLocalizations loc, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<Map<String, dynamic>>(
        value: selectedTicketType,
        decoration: InputDecoration(
          hintText: loc.chooseType,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
        isExpanded: true,
        items: isLoadingTicketTypes
          ? []
          : ticketTypes.map((type) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: type,
                child: Text(
                  type['type_name']?.toString() ?? 
                  type['name']?.toString() ?? loc.unknown,
                  style: const TextStyle(color: Color(0xFF091735)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
            return loc.pleaseSelectTicketType;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDetailsField(AppLocalizations loc, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _detailsController,
        maxLines: 6,
        textAlign: isArabic ? TextAlign.right : TextAlign.left,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: loc.ticketDetails,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return loc.pleaseEnterTicketDetails;
          }
          return null;
        },
      ),
    );
  }

Widget _buildUploadButton(AppLocalizations loc, bool isArabic) {
  return Container(
    height: 50,
    decoration: BoxDecoration(
      color: uploadedFileName != null 
          ? const Color(0xFF10295C) 
          : const Color(0xFF4A6FA5),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: isUploadingFile ? null : _pickAndUploadFile,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          children: [
            if (isUploadingFile) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.uploading,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (uploadedFileName != null) ...[
              // File name in center
              Expanded(
                child: Text(
                  uploadedFileName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Cross icon positioned based on language
              Align(
                alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                child: GestureDetector(
                  onTap: _removeUploadedFile,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ] else ...[
              if (!isArabic) ...[
                Text(
                  loc.uploadAttach,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.upload,
                  color: Colors.white,
                  size: 20,
                ),
              ] else ...[
                const Icon(
                  Icons.upload,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.uploadAttach,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    ),
  );
}


void _removeUploadedFile() {
  final loc = AppLocalizations.of(context)!;
  setState(() {
    uploadedFilePath = null;
    uploadedFileName = null;
  });
  _showSuccessSnackBar(loc.fileRemovedSuccessfully ?? 'File removed successfully');
}

Widget _buildFixedBottomSendButton(AppLocalizations loc, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E49A0).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
          BoxShadow(
            color: const Color(0xFF1E49A0).withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
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
                  : Text(
                      loc.send,
                      style: const TextStyle(
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