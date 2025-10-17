import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

class RunSummaryPage extends StatelessWidget {
  final double distance;
  final Duration duration;
  final List<LatLng> route;
  final Future<void> Function() onSave;
  final void Function() onDiscard;

  const RunSummaryPage({
    super.key,
    required this.distance,
    required this.duration,
    required this.route,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final km = (distance / 1000).toStringAsFixed(2);
    final pace = distance > 0
        ? (duration.inMinutes / (distance / 1000)).toStringAsFixed(2)
        : "0.0";
    final speed = duration.inSeconds > 0
        ? (distance / 1000) / (duration.inSeconds / 3600)
        : 0.0;

    // Converte rota latlong2 → google_maps
    final gRoute = route
        .map((p) => gmaps.LatLng(p.latitude, p.longitude))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Resumo da Corrida")),
      body: Column(
        children: [
          // Mapa compacto mostrando a rota
          SizedBox(
            height: 200,
            child: gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: gRoute.isNotEmpty
                    ? gRoute.first
                    : const gmaps.LatLng(-29.648, -50.78),
                zoom: 14,
              ),
              polylines: {
                gmaps.Polyline(
                  polylineId: const gmaps.PolylineId("route"),
                  points: gRoute,
                  color: Colors.blue,
                  width: 5,
                ),
              },
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),

          const SizedBox(height: 20),
          Text(
            "Corrida finalizada!",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Estatísticas principais
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statCard("Distância", "$km km"),
              _statCard("Tempo", duration.toString().split('.').first),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statCard("Pace", "$pace min/km"),
              _statCard("Velocidade", "${speed.toStringAsFixed(1)} km/h"),
            ],
          ),

          const Spacer(),

          // Botões de ação
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await onSave();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home', // ✅ volta para a Home
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Salvar corrida"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    onDiscard();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home', // ✅ volta para a Home
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text("Descartar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget de estatísticas
  Widget _statCard(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}
