import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'attraction_details_screen.dart';

class CommentManagementScreen extends StatefulWidget {
  const CommentManagementScreen({Key? key}) : super(key: key);

  @override
  State<CommentManagementScreen> createState() => _CommentManagementScreenState();
}

class _CommentManagementScreenState extends State<CommentManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllCommentsWithDetails();
  }

  Future<void> _loadAllCommentsWithDetails() async {
    setState(() {
      _isLoading = true;
    });

    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        c.id AS comment_id, 
        c.comment_text, 
        c.timestamp, 
        c.user_id, 
        u.username, 
        c.attraction_id, 
        a.name AS attraction_name
      FROM comments c
      LEFT JOIN users u ON c.user_id = u.id
      LEFT JOIN attractions a ON c.attraction_id = a.id
      ORDER BY c.timestamp DESC
    ''');

    setState(() {
      _comments = result;
      _isLoading = false;
    });
  }

  void _deleteComment(int commentId) async {
    await _dbHelper.deleteComment(commentId);
    _loadAllCommentsWithDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Comments')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return ListTile(
                  title: Text(comment['comment_text']),
                  subtitle: Text(
                      'User: ${comment['username'] ?? "Unknown"} | Attraction: ${comment['attraction_name'] ?? "Unknown"} | ${comment['timestamp']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteComment(comment['comment_id']),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttractionDetailsScreen(
                          attractionId: comment['attraction_id'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
