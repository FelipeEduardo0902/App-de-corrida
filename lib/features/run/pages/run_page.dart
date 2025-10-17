import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import '../vm/run_vm.dart';
import '../../summary/run_summary_page.dart'; // ✅ nova tela de resumo

class RunPage extends StatefulWidget {
  const RunPage({super.key});

  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> {
  final Completer<gmaps.GoogleMapController> _controller = Completer();

  Future<void> _centralizarNoUsuario() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final controller = await _controller.future;
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(pos.latitude, pos.longitude),
          16,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Localização não disponível: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RunVM>();

    // converte rota
    final route = vm.route
        .map((p) => gmaps.LatLng(p.latitude, p.longitude))
        .toList();

    final km = (vm.distance / 1000).toStringAsFixed(2);
    final duration = vm.elapsed.toString().split(".").first;
    final pace = vm.distance > 0
        ? (vm.elapsed.inMinutes / (vm.distance / 1000)).toStringAsFixed(2)
        : "0.0";
    final speed = vm.elapsed.inSeconds > 0
        ? (vm.distance / 1000) / (vm.elapsed.inSeconds / 3600)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text("Corrida")),
      body: Stack(
        children: [
          gmaps.GoogleMap(
            initialCameraPosition: const gmaps.CameraPosition(
              target: gmaps.LatLng(-29.648, -50.78),
              zoom: 14,
            ),
            myLocationEnabled: true,
            polylines: {
              gmaps.Polyline(
                polylineId: const gmaps.PolylineId("route"),
                points: route,
                color: Colors.orange,
                width: 5,
              ),
            },
            onMapCreated: (controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
          ),

          // Painel estilo Strava
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metric("Tempo", duration),
                    _metric("Distância", "$km km"),
                    _metric("Pace", "$pace min/km"),
                    _metric("Velocidade", "${speed.toStringAsFixed(1)} km/h"),
                  ],
                ),
              ),
            ),
          ),

          // Botões de controle
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                if (!vm.isRunning)
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await vm.start();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Iniciar corrida"),
                  ),
                if (vm.isRunning && !vm.isPaused)
                  ElevatedButton.icon(
                    onPressed: vm.pause,
                    icon: const Icon(Icons.pause),
                    label: const Text("Pausar"),
                  ),
                if (vm.isPaused)
                  ElevatedButton.icon(
                    onPressed: vm.resume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Retomar"),
                  ),
                const SizedBox(height: 8),
                if (vm.isRunning || vm.isPaused)
                  ElevatedButton.icon(
                    onPressed: () async {
                      vm.pause();
                      // vai para tela de resumo
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RunSummaryPage(
                            distance: vm.distance,
                            duration: vm.elapsed,
                            route: vm.route,
                            onSave: vm.stopAndSave,
                            onDiscard: vm.discard,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text("Encerrar corrida"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _centralizarNoUsuario,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Centralizar"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
