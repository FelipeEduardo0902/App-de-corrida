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
              .toStringAsFixed(1)
        : "0.0";

    final routePoints = workout.route
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final start = routePoints.isNotEmpty ? routePoints.first : null;
    final end = routePoints.isNotEmpty ? routePoints.last : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        title: const Text(
          "Detalhes da Corrida",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: Column(
        children: [
          // 🔹 MAPA
          if (routePoints.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: SizedBox(
                height: 250,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: start!,
                    zoom: 15,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId("route"),
                      points: routePoints,
                      color: Colors.orange,
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
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                ),
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

          // 🔹 RESUMO
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Text(
                    formatDate(workout.date),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card principal com métricas
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metric("Distância", "$km km", Icons.route),
                        _metric(
                          "Duração",
                          formatDuration(workout.duration),
                          Icons.timer,
                        ),
                        _metric("Ritmo", "$pace min/km", Icons.directions_run),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Card secundário com detalhes adicionais
                Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _infoRow("Data", formatDate(workout.date)),
                        const Divider(),
                        _infoRow(
                          "Horário de Início",
                          "${workout.date.hour.toString().padLeft(2, '0')}:${workout.date.minute.toString().padLeft(2, '0')}",
                        ),
                        const Divider(),
                        _infoRow(
                          "Duração Total",
                          formatDuration(workout.duration),
                        ),
                        const Divider(),
                        _infoRow("Ritmo Médio", "$pace min/km"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black87, fontSize: 15),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
