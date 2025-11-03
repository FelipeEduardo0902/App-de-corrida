import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../models/workout.dart';

class RunDetailPage extends StatelessWidget {
  final Workout workout;
  const RunDetailPage({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final routePoints = workout.route
        .map((p) => gmaps.LatLng(p.latitude, p.longitude))
        .toList();

    final km = (workout.distance / 1000).toStringAsFixed(2);
    final durationStr = _formatDuration(workout.duration);
    final pace = workout.distance > 0
        ? (workout.duration.inMinutes / (workout.distance / 1000))
              .toStringAsFixed(2)
        : "0.0";
    final speed = workout.duration.inSeconds > 0
        ? (workout.distance / 1000) / (workout.duration.inSeconds / 3600)
        : 0.0;

    final date = workout.date;
    final dateFormatted =
        "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    final timeFormatted =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detalhes da Corrida",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔹 Cabeçalho com resumo visual
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBox("Distância", "$km km"),
                _statBox("Tempo", durationStr),
                _statBox("Pace", "$pace min/km"),
                _statBox("Veloc.", "${speed.toStringAsFixed(1)} km/h"),
              ],
            ),
          ),

          // 🔹 Mapa com trajeto
          Expanded(
            child: Stack(
              children: [
                if (routePoints.isNotEmpty)
                  gmaps.GoogleMap(
                    initialCameraPosition: gmaps.CameraPosition(
                      target: routePoints.first,
                      zoom: 15,
                    ),
                    polylines: {
                      gmaps.Polyline(
                        polylineId: const gmaps.PolylineId("route"),
                        points: routePoints,
                        color: Colors.orange,
                        width: 5,
                      ),
                    },
                    markers: {
                      gmaps.Marker(
                        markerId: const gmaps.MarkerId("start"),
                        position: routePoints.first,
                        infoWindow: const gmaps.InfoWindow(title: "Início"),
                        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                          gmaps.BitmapDescriptor.hueGreen,
                        ),
                      ),
                      gmaps.Marker(
                        markerId: const gmaps.MarkerId("end"),
                        position: routePoints.last,
                        infoWindow: const gmaps.InfoWindow(title: "Fim"),
                        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                          gmaps.BitmapDescriptor.hueRed,
                        ),
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                  )
                else
                  const Center(
                    child: Text(
                      "Mapa não disponível",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),

                // 🔹 Cartão inferior com data/hora e info extra
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Data", style: _infoLabelStyle()),
                            Text(dateFormatted, style: _infoValueStyle()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Horário de início", style: _infoLabelStyle()),
                            Text(timeFormatted, style: _infoValueStyle()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Duração total", style: _infoLabelStyle()),
                            Text(durationStr, style: _infoValueStyle()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Velocidade média", style: _infoLabelStyle()),
                            Text(
                              "${speed.toStringAsFixed(1)} km/h",
                              style: _infoValueStyle(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Voltar",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
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

  // 🔹 Bloco de métricas do topo
  Widget _statBox(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // 🔹 Estilos auxiliares
  TextStyle _infoLabelStyle() =>
      const TextStyle(color: Colors.white70, fontSize: 14);

  TextStyle _infoValueStyle() => const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  // 🔹 Formatação de duração
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return "$h:$m:$s";
  }
}
