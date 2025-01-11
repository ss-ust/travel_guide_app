import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/database_helper.dart';

class AttractionManagementScreen extends StatefulWidget {
  const AttractionManagementScreen({Key? key}) : super(key: key);

  @override
  State<AttractionManagementScreen> createState() => _AttractionManagementScreenState();
}

class _AttractionManagementScreenState extends State<AttractionManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _attractions = [];
  List<Map<String, dynamic>> _cities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    final db = await _dbHelper.database;
    final attractions = await db.query('attractions');
    final cities = await db.query('cities');

    setState(() {
      _attractions = attractions;
      _cities = cities;
      _isLoading = false;
    });
  }

  void _showMapPicker(
    LatLng initialPosition,
    Function(double, double) onCoordinatesPicked,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialPosition: initialPosition,
          onCoordinatesPicked: onCoordinatesPicked,
        ),
      ),
    );
  }

  void _showAddAttractionDialog() {
    String? selectedCityId;
    final nameController = TextEditingController();
    final descController = TextEditingController();
    LatLng? selectedCoordinates;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Attraction'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCityId,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      items: _cities
                          .map((city) => DropdownMenuItem(
                                value: city['id'].toString(),
                                child: Text('${city['name']} (ID: ${city['id']})'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCityId = value;
                          selectedCoordinates = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedCoordinates != null)
                      Text(
                        'Selected Location: Lat: ${selectedCoordinates!.latitude}, Lng: ${selectedCoordinates!.longitude}',
                      ),
                    ElevatedButton(
                      onPressed: selectedCityId == null
                          ? null
                          : () {
                              final city = _cities.firstWhere(
                                (city) => city['id'].toString() == selectedCityId,
                              );
                              _showMapPicker(
                                LatLng(city['latitude'], city['longitude']),
                                (lat, lng) {
                                  setState(() {
                                    selectedCoordinates = LatLng(lat, lng);
                                  });
                                },
                              );
                            },
                      child: const Text('Select Location'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (selectedCityId == null ||
                        nameController.text.trim().isEmpty ||
                        selectedCoordinates == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields and select a location')),
                      );
                      return;
                    }

                    final cityId = int.parse(selectedCityId!);
                    final name = nameController.text.trim();
                    final desc = descController.text.trim();

                    await _dbHelper.insertAttraction({
                      'city_id': cityId,
                      'name': name,
                      'latitude': selectedCoordinates!.latitude,
                      'longitude': selectedCoordinates!.longitude,
                      'description': desc,
                    });

                    Navigator.pop(context);
                    _loadAllData();
                  },
                  child: const Text('Add'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditAttractionDialog(Map<String, dynamic> attraction) {
    final nameController = TextEditingController(text: attraction['name']);
    final descController = TextEditingController(text: attraction['description'] ?? '');
    LatLng selectedCoordinates = LatLng(attraction['latitude'], attraction['longitude']);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Attraction'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selected Location: Lat: ${selectedCoordinates.latitude}, Lng: ${selectedCoordinates.longitude}',
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showMapPicker(
                          selectedCoordinates,
                          (lat, lng) {
                            setState(() {
                              selectedCoordinates = LatLng(lat, lng);
                            });
                          },
                        );
                      },
                      child: const Text('Select Location'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final desc = descController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name cannot be empty')),
                      );
                      return;
                    }

                    await _dbHelper.updateAttraction(attraction['id'], {
                      'name': name,
                      'latitude': selectedCoordinates.latitude,
                      'longitude': selectedCoordinates.longitude,
                      'description': desc,
                    });

                    Navigator.pop(context);
                    _loadAllData();
                  },
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Attractions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ElevatedButton(
                  onPressed: _showAddAttractionDialog,
                  child: const Text('Add New Attraction'),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _attractions.length,
                    itemBuilder: (context, index) {
                      final attraction = _attractions[index];
                      return ListTile(
                        title: Text(attraction['name']),
                        subtitle: Text(
                          'City ID: ${attraction['city_id']} | Lat: ${attraction['latitude']}, Lng: ${attraction['longitude']}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showEditAttractionDialog(attraction);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteAttraction(attraction['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _deleteAttraction(int attractionId) async {
    await _dbHelper.deleteAttraction(attractionId);
    _loadAllData();
  }
}

class MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  final Function(double, double) onCoordinatesPicked;

  const MapPickerScreen({
    Key? key,
    required this.initialPosition,
    required this.onCoordinatesPicked,
  }) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_selectedPosition != null) {
                widget.onCoordinatesPicked(
                  _selectedPosition!.latitude,
                  _selectedPosition!.longitude,
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a location')),
                );
              }
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialPosition,
          zoom: 12,
        ),
        onTap: (position) {
          setState(() {
            _selectedPosition = position;
          });
        },
        markers: _selectedPosition != null
            ? {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selectedPosition!,
                ),
              }
            : {},
      ),
    );
  }
}
