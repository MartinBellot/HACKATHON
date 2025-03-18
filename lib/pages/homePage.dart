import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapapp/components/myColorTheme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mapapp/pages/toolbar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  HomepageState createState() => HomepageState();
}

class HomepageState extends State<Homepage> {
  final MapController _mapController = MapController();
  final LatLng _currentCenter = const LatLng(48.11618809738349, -1.665820539550782);
  LatLng? _userLocation;
  final String _tileLayerId = 'mapbox/dark-v10';

  List<Marker> _stations = [];

  Marker? _selectedDeparture;
  Marker? _selectedArrival;

  final String navitiaApiKey = "1a1375af-15bb-4ce9-a4b5-894e2fa7fe6d";

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchGaresSNCF();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_userLocation!, _mapController.camera.zoom);
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
  }


  Future<void> showDialogWhereYouGo() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: MyColortheme.coolGray1,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Où allez-vous ?⚡️', style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: MyColortheme.noirSorete),),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Entrez une adresse',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (){},
                  child: const Text('Rechercher'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchGaresSNCF() async {
    List<Marker> markers = [];

    try {
      // Charger le fichier JSON local
      String jsonString = await rootBundle.loadString('assets/data/gares-de-voyageurs.json');
      List<dynamic> gares = jsonDecode(jsonString);

      for (var gare in gares) {
        if (gare != null && 
            gare.containsKey('position_geographique') &&
            gare['position_geographique'] != null &&
            gare['position_geographique'].containsKey('lat') &&
            gare['position_geographique'].containsKey('lon')) {
          
          final double lat = double.tryParse(gare['position_geographique']['lat'].toString()) ?? 0.0;
          final double lon = double.tryParse(gare['position_geographique']['lon'].toString()) ?? 0.0;

          if (lat != 0.0 && lon != 0.0) {
            markers.add(
              Marker(
                point: LatLng(lat, lon),
                width: 30,
                height: 30,
                child: Tooltip(
                  message: gare['nom'] ?? "Gare inconnue", // Vérifie que le nom existe
                  child: CircleAvatar(
                    backgroundColor: MyColortheme.jauneSafran,
                    child: Text(
                      gare['nom']?.substring(0, 1) ?? "?",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: MyColortheme.noirSorete,
                      ),
                    ),
                  )
                ),
              ),
            );
          }
        }
      }
      setState(() {
        _stations = markers;
        _isLoading = false;
      });
      print("Nombre total de gares chargées: ${_stations.length}");
    } catch (e) {
      print("Erreur lors du chargement des gares: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColortheme.darkbg,
        foregroundColor: Colors.white,
        title: Image.asset(
          'images/realicon.png',
          width: 100,
          height: 100,
        ),
        actions: [
          IconButton(
            //color: MyColortheme.noirSorete,
            onPressed: (){
              showDialogWhereYouGo();
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            //color: MyColortheme.noirSorete,
            onPressed: (){
              _fetchGaresSNCF();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            //color: MyColortheme.noirSorete,
            onPressed: (){
            },
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: _isLoading ? Center(child: SpinKitDoubleBounce(color: MyColortheme.bleuAnthracite,)) :
        Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                key: ValueKey(_tileLayerId),
                mapController: _mapController,
                options: MapOptions(
                  backgroundColor: MyColortheme.backgroundColor,
                  initialCenter: _currentCenter,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                    additionalOptions: {
                      'accessToken': 'pk.eyJ1IjoibWFydGluYmVsbG90IiwiYSI6ImNsbTUyam5yOTIxdDAzZW4xaXd6dDFzajQifQ.73WXuS78PB-6ZDZMUaZChg',
                      'id': _tileLayerId,
                    },
                    userAgentPackageName: 'com.example.app',
                  ),
                  if (_userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation!,
                          width: 40,
                          height: 40,
                          child: SpinKitDoubleBounce(color: MyColortheme.bleuAnthracite,)
                        ),
                      ],
                    ),
                  MarkerLayer(markers: _stations),
                  if (_selectedDeparture != null)
                    MarkerLayer(markers: [_selectedDeparture!]),
                  if (_selectedArrival != null)
                    MarkerLayer(markers: [_selectedArrival!]),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                children: [
                  FloatingActionButton(
                    backgroundColor: MyColortheme.jauneSafran,
                    onPressed: _zoomIn,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    backgroundColor: MyColortheme.jauneSafran,
                    onPressed: _zoomOut,
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Toolbar(
                stations: [], 
                onSearchArrival: (marker) {
                  setState(() {
                    _selectedArrival = marker;
                  });
                },
                onSearchDepart: (marker) {
                  setState(() {
                    _selectedDeparture = marker;
                  
                  });
                },
              ),
            )
          ],
        ),
        
    );
  }
}