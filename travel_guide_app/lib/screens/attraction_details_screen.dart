import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';

class AttractionDetailsScreen extends StatefulWidget {
  final int attractionId;

  const AttractionDetailsScreen({Key? key, required this.attractionId}) : super(key: key);

  @override
  State<AttractionDetailsScreen> createState() => _AttractionDetailsScreenState();
}

class _AttractionDetailsScreenState extends State<AttractionDetailsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _attraction;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;
  bool _visited = false;
  int? _currentUserId;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final attractionResult = await _dbHelper.getAttractionById(widget.attractionId);
    _attraction = attractionResult.isNotEmpty ? attractionResult.first : null;

    _currentUserId = await _authService.getCurrentUserId();
    _isLoggedIn = _currentUserId != null;
    _isAdmin = _isLoggedIn && await _authService.isAdmin();

    bool visited = false;
    if (_isLoggedIn) {
      visited = await _dbHelper.isAttractionVisitedByUser(_currentUserId!, widget.attractionId);
    }

    final comments = await _fetchCommentsWithUsernames(widget.attractionId);

    setState(() {
      _visited = visited;
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchCommentsWithUsernames(int attractionId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT c.id AS comment_id, c.comment_text, c.timestamp, c.user_id, u.username
      FROM comments c
      LEFT JOIN users u ON c.user_id = u.id
      WHERE c.attraction_id = ?
      ORDER BY c.timestamp DESC
    ''', [attractionId]);
    return result;
  }

  Future<void> _toggleVisited() async {
    if (!_isLoggedIn) {
      _showLoginSnackBar("Log in to mark this attraction as visited.");
      return;
    }

    _visited = !_visited;
    await _dbHelper.setAttractionVisited(_currentUserId!, widget.attractionId, _visited);
    setState(() {});
  }

  void _showLoginSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.white))),
    );
  }

  void _showEditCommentDialog(Map<String, dynamic> comment) async {
    final commentController = TextEditingController(text: comment['comment_text']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              labelText: 'Your comment',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _dbHelper.updateComment(comment['comment_id'], {'comment_text': commentController.text});
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _deleteComment(int commentId) async {
    await _dbHelper.deleteComment(commentId);
    _loadData();
  }

  Widget _buildCommentTile(Map<String, dynamic> comment) {
    final isOwnComment = _isLoggedIn && comment['user_id'] == _currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(comment['comment_text']),
        subtitle: Text('${comment['username'] ?? "Unknown User"} • ${comment['timestamp']}'),
        trailing: (isOwnComment || _isAdmin)
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditCommentDialog(comment);
                  } else if (value == 'delete') {
                    _deleteComment(comment['comment_id']);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              )
            : null,
      ),
    );
  }

  void _showAddCommentDialog() {
    if (!_isLoggedIn) {
      _showLoginSnackBar("Log in to add a comment.");
      return;
    }

    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              labelText: 'Your comment',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newComment = {
                  'attraction_id': widget.attractionId,
                  'user_id': _currentUserId,
                  'comment_text': commentController.text,
                };
                await _dbHelper.insertComment(newComment);
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_attraction?['name'] ?? 'Attraction Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attraction == null
              ? const Center(child: Text('Attraction not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 300,
                        child: GoogleMap(
                          onMapCreated: (controller) => _mapController = controller,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _attraction!['latitude'] ?? 0.0,
                              _attraction!['longitude'] ?? 0.0,
                            ),
                            zoom: 14.0,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(widget.attractionId.toString()),
                              position: LatLng(
                                _attraction!['latitude'] ?? 0.0,
                                _attraction!['longitude'] ?? 0.0,
                              ),
                              infoWindow: InfoWindow(
                                title: _attraction!['name'],
                              ),
                            ),
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _attraction!['name'],
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_attraction!['description'] ?? 'No description available'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Visited: '),
                          Switch(
                            value: _visited,
                            onChanged: (val) => _toggleVisited(),
                          ),
                          if (!_isLoggedIn)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text('Log in to mark visited', style: TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Comments',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._comments.map(_buildCommentTile).toList(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoggedIn ? _showAddCommentDialog : () {
                            _showLoginSnackBar("Log in to add a comment.");
                          },
                          child: const Text('Add Comment'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
