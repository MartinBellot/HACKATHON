import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mapapp/components/myColorTheme.dart';

class JourneyDialog extends StatefulWidget {
  final String from;
  final String to;
  const JourneyDialog({super.key, required this.from, required this.to});

  @override
  JourneyDialogState createState() => JourneyDialogState();
}

class JourneyDialogState extends State<JourneyDialog> {
  final String navitiaApiKey = "1a1375af-15bb-4ce9-a4b5-894e2fa7fe6d";
  final String regionId = "sncf";
  List<dynamic> journeys = [];
  bool isLoading = true;

  Future<String?> getPlaceId(String placeName) async {
  final String url = "https://api.navitia.io/v1/coverage/sncf/places?q=$placeName";

  try {
    final response = await http.get(Uri.parse(url), headers: {"Authorization": navitiaApiKey});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data["places"].isNotEmpty) {
        for (var place in data["places"]) {
          if (place["embedded_type"] == "stop_area") { // On filtre uniquement les gares
            return place["id"];
          }
        }
      }
    }
  } catch (e) {
    print("Erreur lors de la récupération du place.id: $e");
  }
  return null;
}

  Future<void> getJourneys(String from, String to) async {
    final fromId = await getPlaceId(from);
    final toId = await getPlaceId(to);

    if (fromId == null || toId == null) {
      print("Impossible de trouver les lieux spécifiés.");
      return;
    }
    debugPrint("From ID: $fromId, To ID: $toId");

    final String url = "https://api.navitia.io/v1/coverage/sncf/journeys?from=$fromId&to=$toId";
    
    try {
      final response = await http.get(Uri.parse(url), headers: {"Authorization": navitiaApiKey});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Trajets trouvés : ${data['journeys']}");
        setState(() {
          journeys = data["journeys"];
          isLoading = false;
        });
      } else {
        print("Erreur API Navitia: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Erreur lors de la récupération des trajets: $e");
    }
  }
  @override
  void initState() {
    super.initState();
    getJourneys(widget.from, widget.to);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      decoration: BoxDecoration(
        color: MyColortheme.darkbg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: isLoading
          ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitChasingDots(color: MyColortheme.lightblue,),
                const SizedBox(height: 5,),
                const Text("Rercherche du trajet le plus optimisé...", style: TextStyle(color: Colors.white, fontSize: 20),),
              ],
            )
          )
          : journeys.isEmpty
              ? const Center(child: Text("Aucun trajet disponible"))
              : ListView.builder(
                  itemCount: journeys.length,
                  itemBuilder: (context, index) {
                    final journey = journeys[index];
                    final duration = journey["duration"] ?? 0;
                    final departure = journey["departure_date_time"] ?? "";
                    final arrival = journey["arrival_date_time"] ?? "";
                    final sections = journey["sections"] ?? [];

                    return Card(
                      color: MyColortheme.darkbg,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset("images/realicon.png", height: 100),
                                Text(
                                  "Durée: ${Duration(seconds: duration).inMinutes} min",
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("🛫 Départ:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500])),
                                    Text(_formatDateTime(departure), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("🛬 Arrivée:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500])),
                                    Text(_formatDateTime(arrival), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(FontAwesomeIcons.leaf, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Text("Consommation: ${journey["co2_emission"]["value"] ?? 0} ${journey["co2_emission"]["unit"] ?? "Impossible de récupérer la consommation"}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            Column(
                              children: sections.asMap().entries.map<Widget>((entry) {
                                int index = entry.key;
                                var section = entry.value;

                                final mode = section["mode"] ?? section["type"] ?? "inconnu";
                                final from = section["from"]?["name"] ?? "?";
                                final to = section["to"]?["name"] ?? "?";
                                final lineInfo = section["display_informations"]?["name"] ?? "";
                                final departureTime = _formatDateTime(section["departure_date_time"] ?? "");
                                final arrivalTime = _formatDateTime(section["arrival_date_time"] ?? "");

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _getTransportIcon(mode),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (from != "?" && to != "?")...[
                                                Text(
                                                  "$from → $to",
                                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey[500]),
                                                ),
                                              ] else...[
                                                Text(
                                                  "Attente/Changement",
                                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey[500]),
                                                ),
                                              ],
                                              Text(
                                                "Mode: ${(mode).toUpperCase()} | Ligne: ${lineInfo ?? "inconnue"}",
                                                style: TextStyle(color: Colors.grey[700]),
                                              ),
                                              Text(
                                                "Départ: $departureTime - Arrivée: $arrivalTime",
                                                style: TextStyle(color: Colors.grey[700]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (index < sections.length - 1)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
                                        child: Container(
                                          height: 20,
                                          width: 2,
                                          color: Colors.deepPurple.withOpacity(0.5),
                                        ),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.center,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                label: const Text("Réserver mon trajet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                icon: const Icon(Icons.play_arrow, color: Colors.black),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyColortheme.lightblue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDateTime(String dateTime) {
    if (dateTime.isEmpty) return "";
    final parsedDate = DateTime.parse(dateTime);
    return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);
  }

  Icon _getTransportIcon(String mode) {
    switch (mode) {
      case "walking":
        return const Icon(Icons.directions_walk, color: Colors.blue);
      case "bus":
        return const Icon(Icons.directions_bus, color: Colors.orange);
      case "train":
        return const Icon(Icons.train, color: Colors.green);
      case "tram":
        return const Icon(Icons.tram, color: Colors.purple);
      case "metro":
        return const Icon(Icons.subway, color: Colors.red);
      case "public_transport":
        return const Icon(Icons.directions_transit, color: Colors.teal);
      case "waiting":
        return const Icon(Icons.access_time, color: Colors.grey);
      default:
        return const Icon(Icons.directions, color: Colors.grey);
    }
  }
}