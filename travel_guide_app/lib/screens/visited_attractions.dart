import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import 'attraction_details_screen.dart';

class VisitedAttractionsScreen extends StatefulWidget {
  const VisitedAttractionsScreen({Key? key}) : super(key: key);

  @override
  State<VisitedAttractionsScreen> createState() => _VisitedAttractionsScreenState();
}

class _VisitedAttractionsScreenState extends State<VisitedAttractionsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _visitedAttractions = [];
  bool _isLoading = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadVisitedAttractions();
  }

  Future<void> _loadVisitedAttractions() async {
    setState(() {
      _isLoading = true;
    });

    _currentUserId = await _authService.getCurrentUserId();

    if (_currentUserId != null) {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT a.id AS attraction_id, a.name, a.description, a.latitude, a.longitude, c.name AS city_name
        FROM visited v
        INNER JOIN attractions a ON v.attraction_id = a.id
        INNER JOIN cities c ON a.city_id = c.id
        WHERE v.user_id = ? AND v.visited = 1
      ''', [_currentUserId]);

      setState(() {
        _visitedAttractions = result;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visited Attractions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visitedAttractions.isEmpty
              ? const Center(child: Text('No visited attractions found.'))
              : ListView.builder(
                  itemCount: _visitedAttractions.length,
                  itemBuilder: (context, index) {
                    final attraction = _visitedAttractions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(
                          attraction['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'City: ${attraction['city_name']}',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttractionDetailsScreen(
                                attractionId: attraction['attraction_id'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
