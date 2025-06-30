import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart'; // Import your auth provider

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = FlutterSecureStorage();

  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _middleNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  String phoneNumber = '';
  String userID = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    _firstNameController.text = await _storage.read(key: 'first_name') ?? '';
    _middleNameController.text = await _storage.read(key: 'middle_name') ?? '';
    _lastNameController.text = await _storage.read(key: 'last_name') ?? '';
    phoneNumber = await _storage.read(key: 'phone_number') ?? '';
    userID = await _storage.read(key: 'user_id') ?? '';
    setState(() {});
  }

  Future<void> updateProfile() async {
    final token = await _storage.read(key: 'token');

    final response = await http.put(
      Uri.parse('http://fawran.ddns.net:8080/ords/emdad/fawran/user/profile/update'),
      headers: {
        'Content-Type': 'application/json',
        'token': token ?? '',
      },
      body: json.encode({
        'user_id': userID,
        'first_name': _firstNameController.text,
        'middle_name': _middleNameController.text,
        'last_name': _lastNameController.text,
      }),
    );

    if (response.statusCode == 200) {
      await _storage.write(key: 'first_name', value: _firstNameController.text);
      await _storage.write(key: 'middle_name', value: _middleNameController.text);
      await _storage.write(key: 'last_name', value: _lastNameController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update failed')),
      );
    }
  }

  Future<void> logout() async {
    // Clear secure storage
    await _storage.deleteAll();

    // Call logout from authProvider
    ref.read(authProvider.notifier).logout();

    // Navigate to login screen
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Phone Number: $phoneNumber'),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  TextFormField(
                    controller: _middleNameController,
                    decoration: const InputDecoration(labelText: 'Middle Name'),
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: updateProfile,
                    child: const Text('Update Profile'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextButton.icon(
                  onPressed: logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
