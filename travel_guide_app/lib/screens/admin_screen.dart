import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'city_management_screen.dart';
import 'attraction_management_screen.dart';
import 'comment_management_screen.dart';
import 'database_view_screen.dart';

class AdminScreen extends StatelessWidget {
  AdminScreen({Key? key}) : super(key: key);

  final AuthService _authService = AuthService();

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CityManagementScreen()),
                );
              },
              child: const Text('Manage Cities'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AttractionManagementScreen()),
                );
              },
              child: const Text('Manage Attractions'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CommentManagementScreen()),
                );
              },
              child: const Text('Manage Comments'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DatabaseViewScreen()),
                );
              },
              child: const Text('View Entire Database'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () => _logout(context),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
