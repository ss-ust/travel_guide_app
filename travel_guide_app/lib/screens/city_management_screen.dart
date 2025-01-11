import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/database_helper.dart';

class CityManagementScreen extends StatefulWidget {
  const CityManagementScreen({Key? key}) : super(key: key);

  @override
  State<CityManagementScreen> createState() => _CityManagementScreenState();
}

class _CityManagementScreenState extends State<CityManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _cities = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCities();
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
      });
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

  void _showMapPicker(Function(double, double) onCoordinatesPicked) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(onCoordinatesPicked: onCoordinatesPicked),
      ),
    );
  }

  void _showAddCityDialog() {
    final nameController = TextEditingController();
    double? selectedLat;
    double? selectedLng;

    String? nameError;
    String? latLngError;

    void _validateAndAddCity() async {
      final name = nameController.text.trim();

      if (name.isEmpty) {
        setState(() => nameError = 'Name cannot be empty');
      } else {
        nameError = null;
      }

      if (selectedLat == null || selectedLng == null) {
        setState(() => latLngError = 'Please select a location on the map');
      } else {
        latLngError = null;
      }

      if (nameError == null && latLngError == null) {
        try {
          await _dbHelper.insertCity({
            'name': name,
            'latitude': selectedLat,
            'longitude': selectedLng,
          });
          Navigator.pop(context); 
          _loadCities(); 
        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to add city: $e';
          });
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add City'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'City Name',
                      errorText: nameError,
                    ),
                  ),
                  if (selectedLat != null && selectedLng != null)
                    Text('Selected Location: Lat: $selectedLat, Lng: $selectedLng'),
                  if (latLngError != null)
                    Text(
                      latLngError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ElevatedButton(
                    onPressed: () => _showMapPicker((lat, lng) {
                      setState(() {
                        selectedLat = lat;
                        selectedLng = lng;
                      });
                    }),
                    child: const Text('Select Location'),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: _validateAndAddCity,
                child: const Text('Add'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showEditCityDialog(Map<String, dynamic> city) {
  final nameController = TextEditingController(text: city['name']);
  double? selectedLat = city['latitude'];
  double? selectedLng = city['longitude'];

  String? nameError;
  String? latLngError;

  void _validateAndUpdateCity() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      setState(() => nameError = 'Name cannot be empty');
    } else {
      nameError = null;
    }

    if (selectedLat == null || selectedLng == null) {
      setState(() => latLngError = 'Please select a location on the map');
    } else {
      latLngError = null;
    }

    if (nameError == null && latLngError == null) {
      try {
        await _dbHelper.updateCity(city['id'], {
          'name': name,
          'latitude': selectedLat,
          'longitude': selectedLng,
        });
        Navigator.pop(context); 
        _loadCities(); 
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to update city: $e';
        });
      }
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Edit City'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'City Name',
                    errorText: nameError,
                  ),
                ),
                if (selectedLat != null && selectedLng != null)
                  Text('Selected Location: Lat: $selectedLat, Lng: $selectedLng'),
                if (latLngError != null)
                  Text(
                    latLngError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ElevatedButton(
                  onPressed: () => _showMapPicker((lat, lng) {
                    setState(() {
                      selectedLat = lat;
                      selectedLng = lng;
                    });
                  }),
                  child: const Text('Select Location'),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: _validateAndUpdateCity,
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      });
    },
  );
}

  void _confirmDeleteCity(int cityId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete City'),
          content: const Text('Are you sure you want to delete this city? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _dbHelper.deleteCity(cityId);
                  _loadCities();
                } catch (e) {
                  setState(() {
                    _errorMessage = 'Failed to delete city: $e';
                  });
                }
              },
              child: const Text('Delete'),
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
        title: const Text('Manage Cities'),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              color: Colors.redAccent,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ElevatedButton(
            onPressed: _showAddCityDialog,
            child: const Text('Add New City'),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _cities.length,
                    itemBuilder: (context, index) {
                      final city = _cities[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text('${city['name']} (ID: ${city['id']})'),
                          subtitle: Text('Lat: ${city['latitude']}, Lng: ${city['longitude']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showEditCityDialog(city);                                
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmDeleteCity(city['id']),
                              ),
                            ],
                          ),
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

class MapPickerScreen extends StatefulWidget {
  final Function(double, double) onCoordinatesPicked;

  const MapPickerScreen({Key? key, required this.onCoordinatesPicked}) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedPosition;

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
                  const SnackBar(content: Text('Please select a location on the map')),
                );
              }
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(39.92077, 32.85411), 
          zoom: 6, 
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

