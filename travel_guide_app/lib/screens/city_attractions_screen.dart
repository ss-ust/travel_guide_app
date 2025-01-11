import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/database_helper.dart';
import 'attraction_details_screen.dart';

class CityAttractionsScreen extends StatefulWidget {
  final int cityId;

  const CityAttractionsScreen({Key? key, required this.cityId}) : super(key: key);

  @override
  State<CityAttractionsScreen> createState() => _CityAttractionsScreenState();
}

class _CityAttractionsScreenState extends State<CityAttractionsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _attractions = [];
  List<Map<String, dynamic>> _filteredAttractions = [];
  Map<String, dynamic>? _city;
  bool _isLoading = false;
  Set<Marker> _markers = {};
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

    try {
      final cities = await _dbHelper.getCities();
      _city = cities.firstWhere((city) => city['id'] == widget.cityId);

      final attractions = await _dbHelper.getAttractionsByCity(widget.cityId);
      _updateMarkers(attractions);

      setState(() {
        _attractions = attractions;
        _filteredAttractions = attractions;
      });
    } catch (e) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMarkers(List<Map<String, dynamic>> attractions) {
    final markers = attractions.map((attraction) {
      return Marker(
        markerId: MarkerId('attraction_${attraction['id']}'),
        position: LatLng(attraction['latitude'], attraction['longitude']),
        infoWindow: InfoWindow(
          title: attraction['name'],
          snippet: 'Tap to view details',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttractionDetailsScreen(
                  attractionId: attraction['id'],
                ),
              ),
            );
          },
        ),
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });
  }

  void _filterAttractions(String query) {
    setState(() {
      _filteredAttractions = _attractions
          .where((attraction) => attraction['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_city?['name'] ?? 'City Attractions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 300,
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _city != null
                          ? LatLng(_city!['latitude'], _city!['longitude'])
                          : const LatLng(39.92077, 32.85411),
                      zoom: 12,
                    ),
                    markers: _markers,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: _filterAttractions,
                    decoration: const InputDecoration(
                      labelText: 'Search Attractions',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredAttractions.length,
                    itemBuilder: (context, index) {
                      final attraction = _filteredAttractions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.teal),
                          title: Text(
                            attraction['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            attraction['description'] ?? 'No description available',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AttractionDetailsScreen(
                                  attractionId: attraction['id'],
                                ),
                              ),
                            );
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
