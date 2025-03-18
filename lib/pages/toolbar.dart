import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapapp/components/myColorTheme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:mapapp/pages/JourneyPage.dart';

class Station {
  final String name;
  final double lat;
  final double lon;

  Station(this.name, this.lat, this.lon);
}

class Toolbar extends StatefulWidget {
  final List<Station> stations;
  final Function(Marker)? onSearchDepart;
  final Function(Marker)? onSearchArrival;
  const Toolbar({super.key, required this.stations, this.onSearchDepart, this.onSearchArrival});

  @override
  ToolbarState createState() => ToolbarState();
}

class ToolbarState extends State<Toolbar> {
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();


  Marker? _selectedDepartureMarker;
  Marker? _selectedArrivalMarker;

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      initialEntryMode: TimePickerEntryMode.input,
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<Map<String, double>?> getCoordinatesFromLocation(String location) async {
    final String url = "https://nominatim.openstreetmap.org/search?format=json&q=$location";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final double lat = double.parse(data[0]["lat"]);
          final double lon = double.parse(data[0]["lon"]);
          return {"latitude": lat, "longitude": lon};
        } else {
          print("Lieu non trouvé");
          return null;
        }
      } else {
        print("Erreur API: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur lors de la récupération des coordonnées: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: MyColortheme.darkbg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planifier votre voyage',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Trouvez le meilleur itinéraire',
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          _buildInputField(_departureController, 'Départ', FontAwesomeIcons.locationArrow),
          const SizedBox(height: 10),
          _buildInputField(_arrivalController, 'Destination', FontAwesomeIcons.mapMarkerAlt),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateTimeField('Date', FontAwesomeIcons.calendarAlt, DateFormat('dd/MM/yyyy').format(selectedDate), _selectDate),
              _buildDateTimeField('Heure', FontAwesomeIcons.clock, selectedTime.format(context), _selectTime),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.leaf, color: MyColortheme.vertPomme, size: 18),
              const SizedBox(width: 10),
              Text(
                'Déterminez votre empreinte carbone',
                style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoTile('Mode de transport intelligent', 'Notre IA détermine le meilleur mode de transport.', FontAwesomeIcons.robot, Colors.indigo[900]!),
          _buildInfoTile('Gares SNCF', '50 gares principales disponibles sur la carte.', FontAwesomeIcons.train, Colors.indigo[900]!),
          _buildInfoTile('Parcs automobiles SNCF', '16 parcs disponibles.', FontAwesomeIcons.car, Colors.redAccent),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColortheme.lightpink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              if (_departureController.text.isNotEmpty && _arrivalController.text.isNotEmpty) {
                
                showDialog(
                  context: context, 
                  builder: (BuildContext context) {
                    return Dialog(
                      child: JourneyDialog(from: _departureController.text, to: _arrivalController.text),
                    );
                  },
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Veuillez sélectionner un lieu de départ et une destination.'),
                  backgroundColor: Colors.redAccent,
                ));
              }

            },
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text(
              'Rechercher',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      onSubmitted: (value) {
        getCoordinatesFromLocation(value).then((coordinates) {
          debugPrint("Coordonnées: $coordinates");
          if (coordinates != null) {
            if (label == "Départ" && widget.onSearchDepart != null) {
              _selectedDepartureMarker = Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(coordinates["latitude"]!, coordinates["longitude"]!),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              );
              widget.onSearchDepart!(_selectedDepartureMarker!);
            } else if (label == "Destination" && widget.onSearchArrival != null) {
              _selectedArrivalMarker = Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(coordinates["latitude"]!, coordinates["longitude"]!),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 40,
                ),
              );
              widget.onSearchArrival!( _selectedArrivalMarker!);
            }
            setState(() {
              
            });
          }
        });
      },
      style: TextStyle(fontSize: 16, color: Colors.white),
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 16, color: Colors.white),
        hintStyle: TextStyle(fontSize: 16, color: Colors.white),
        prefixIcon: Icon(icon, color: MyColortheme.lightblue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildDateTimeField(String label, IconData icon, String value, Function() onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: MyColortheme.lightblue, size: 18),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: MyColortheme.bleuAnthracite),
                ),
                Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
