import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/utils/formatters.dart';
import '../run/models/workout.dart';

class WorkoutDetailPage extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    final km = (workout.distance / 1000).toStringAsFixed(2);
    final pace = workout.distance > 0
        ? (workout.duration.inMinutes / (workout.distance / 1000))
              .toStringAsFixed(2)
        : "0.0";

    final routePoints = workout.route
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final start = routePoints.isNotEmpty ? routePoints.first : null;
    final end = routePoints.isNotEmpty ? routePoints.last : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes da Corrida"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // MAPA GOOGLE
          if (routePoints.isNotEmpty)
            Expanded(
              flex: 2,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: start!, zoom: 15),
                polylines: {
                  Polyline(
                    polylineId: const PolylineId("route"),
                    points: routePoints,
                    color: Colors.blueAccent,
                    width: 5,
                  ),
                },
                markers: {
                  Marker(
                    markerId: const MarkerId("start"),
                    position: start!,
                    infoWindow: const InfoWindow(title: "Início"),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                  ),
                  if (end != null)
                    Marker(
                      markerId: const MarkerId("end"),
                      position: end,
                      infoWindow: const InfoWindow(title: "Fim"),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                },
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapType: MapType.normal,
              ),
            )
          else
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const Text(
                "Nenhum trajeto registrado.",
                style: TextStyle(color: Colors.grey),
              ),
            ),

          // DETALHES DA CORRIDA
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        formatDate(workout.date),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const Divider(),
                      _buildInfoRow("Distância", "$km km"),
                      _buildInfoRow(
                        "Duração",
                        formatDuration(workout.duration),
                      ),
                      _buildInfoRow("Ritmo médio", "$pace min/km"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
