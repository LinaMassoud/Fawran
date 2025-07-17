import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/generated/app_localizations.dart';

import '../providers/auth_provider.dart';

class UserDetailsScreen extends ConsumerStatefulWidget {
  const UserDetailsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> {
  final _storage = FlutterSecureStorage();

  String firstName = '';
  String middleName = '';
  String lastName = '';
  String phoneNumber = '';
  String userID = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    firstName = await _storage.read(key: 'first_name') ?? '';
    middleName = await _storage.read(key: 'middle_name') ?? '';
    lastName = await _storage.read(key: 'last_name') ?? '';
    phoneNumber = await _storage.read(key: 'phone_number') ?? '';
    userID = await _storage.read(key: 'user_id') ?? '';
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> logout() async {
    // Clear secure storage
    await _storage.deleteAll();

    // Call logout from authProvider
    ref.read(authProvider.notifier).logout(ref);

    // Navigate to login screen
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.myInformation),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Avatar
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB8B8B8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // User Details Cards
                  _buildInfoCard(localizations.userID, userID),
                  const SizedBox(height: 12),
                  _buildInfoCard(localizations.phoneNumber, phoneNumber),
                  const SizedBox(height: 12),
                  _buildInfoCard(localizations.firstName, firstName),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    localizations.middleName, 
                    middleName.isEmpty ? localizations.notProvided : middleName
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(localizations.lastName, lastName),
                  
                  const Spacer(),
                  
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? localizations.notProvided : value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}