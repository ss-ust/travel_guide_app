import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'database_helper.dart';
import '/utils/utils.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Store user session info
  Future<void> storeUserSession(int userId, String role) async {
    await _storage.write(key: 'user_id', value: userId.toString());
    await _storage.write(key: 'role', value: role);
  }

  // Retrieve user session info
  Future<Map<String, String?>> getUserSession() async {
    final userId = await _storage.read(key: 'user_id');
    final role = await _storage.read(key: 'role');
    return {'user_id': userId, 'role': role};
  }

  // Clear user session (logout)
  Future<void> logout() async {
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'role');
  }

 Future<Map<String, dynamic>> login(String username, String password) async {
  final users = await _dbHelper.getUserByUsername(username);

  if (users.isEmpty) {
    return {'success': false, 'message': 'User not found'};
  }

  final user = users.first;
  final storedPassword = user['password'] as String;
  final storedRole = user['role'] as String;
  final userId = user['id'] as int;

  // Hash the input password and compare with stored hash
  if (hashPassword(password) == storedPassword) {
    await storeUserSession(userId, storedRole);
    return {'success': true, 'role': storedRole};
  } else {
    return {'success': false, 'message': 'Invalid password'};
  }
}

  Future<bool> isAdmin() async {
    final session = await getUserSession();
    return session['role'] == 'admin';
  }

  Future<int?> getCurrentUserId() async {
    final session = await getUserSession();
    if (session['user_id'] != null) {
      return int.tryParse(session['user_id']!);
    }
    return null;
  }
}
