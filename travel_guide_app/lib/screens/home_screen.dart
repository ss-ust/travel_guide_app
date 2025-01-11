import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import 'city_attractions_screen.dart';
import 'login_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _filteredCities = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;
  bool _isLoggedIn = false; 
  String? _userRole; 
  late GoogleMapController _mapController;

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadCities();
  }

  Future<void> _checkLoginStatus() async {
    final session = await _authService.getUserSession();
    _isLoggedIn = session['user_id'] != null;
    if (_isLoggedIn) {
      final userId = int.tryParse(session['user_id']!);
      if (userId != null) {
        final user = await _dbHelper.getUserById(userId);
        if (user.isNotEmpty) {
          _userRole = user.first['role'] as String?;
        }
      }
    }
    setState(() {});
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cities = await _dbHelper.getCities();
      setState(() {
        _cities = cities;
        _filteredCities = cities;
      });
      _updateMarkers(); 
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load cities: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMarkers() {
    Set<Marker> newMarkers = {};
    for (var city in _cities) {
      final cityId = city['id'];
      final cityName = city['name'].toString();
      final lat = city['latitude'] as double;
      final lng = city['longitude'] as double;

      final marker = Marker(
        markerId: MarkerId(cityId.toString()),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: cityName,
          snippet: 'Tap to view details',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CityAttractionsScreen(cityId: cityId),
              ),
            ).then((_) {
              _loadCities();
            });
          },
        ),
      );

      newMarkers.add(marker);
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = false;
      _userRole = null;
    });
    Navigator.pushReplacementNamed(context, '/');
  }

  void _filterCities(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCities = _cities;
      } else {
        _filteredCities = _cities.where((city) {
          final cityName = city['name'].toString().toLowerCase();
          return cityName.contains(_searchQuery);
        }).toList();
      }
    });
  }

  void _goToLogin() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    ).then((_) {
      _checkLoginStatus();
    });
  }

  void _goToAdmin() {
    Navigator.pushNamed(context, '/admin').then((_) {
      _loadCities();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cities'),
        actions: [
          if (_isLoggedIn && _userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin',
              onPressed: _goToAdmin,
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            if (_isLoggedIn)
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Visited Attractions'),
                onTap: () {
                  Navigator.pop(context); 
                  Navigator.pushNamed(context, '/visited_attractions');
                },
              ),
            if (_isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context); 
                  _logout();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: _goToLogin, 
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              color: Colors.redAccent,
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          SizedBox(
            height: 300, 
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(39.92077, 32.85411), 
                zoom: 5.0, 
              ),
              markers: _markers,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterCities,
              decoration: const InputDecoration(
                labelText: 'Search Cities',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCities.isEmpty
                    ? const Center(child: Text('No matching cities found.'))
                    : ListView.builder(
                        itemCount: _filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = _filteredCities[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.location_city),
                              title: Text(
                                city['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CityAttractionsScreen(cityId: city['id']),
                                  ),
                                ).then((_) {
                                  _loadCities();
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
