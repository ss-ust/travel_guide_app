import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class DatabaseViewScreen extends StatefulWidget {
  const DatabaseViewScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseViewScreen> createState() => _DatabaseViewScreenState();
}

class _DatabaseViewScreenState extends State<DatabaseViewScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _attractions = [];
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _visited = [];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _dbHelper.getAllUsers();
      final db = await _dbHelper.database;

      final cities = await db.query('cities');
      final attractions = await db.query('attractions');
      final comments = await db.query('comments');
      final visited = await db.query('visited');

      setState(() {
        _users = users;
        _cities = cities;
        _attractions = attractions;
        _comments = comments;
        _visited = visited;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load database: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildListView(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No records found.'));
    }
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final row = data[index];
        final title = row.containsKey('id') ? 'ID: ${row['id']}' : 'Record $index';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: row.entries.map((entry) {
                  return ListTile(
                    title: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Database View'),
          backgroundColor: theme.colorScheme.primary,
          elevation: 2,
          bottom: TabBar(
            indicator: BoxDecoration(
              color: theme.colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: const [
              Tab(text: 'Users'),
              Tab(text: 'Cities'),
              Tab(text: 'Attractions'),
              Tab(text: 'Comments'),
              Tab(text: 'Visited'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : TabBarView(
                    children: [
                      _buildListView(_users),
                      _buildListView(_cities),
                      _buildListView(_attractions),
                      _buildListView(_comments),
                      _buildListView(_visited),
                    ],
                  ),
      ),
    );
  }
}
