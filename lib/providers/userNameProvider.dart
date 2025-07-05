import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final userNameProvider = FutureProvider<String>((ref) async {
  final storage = FlutterSecureStorage();
  final firstName = await storage.read(key: 'first_name') ?? '';
  final lastName = await storage.read(key: 'last_name') ?? '';
  return '$firstName $lastName';
});
