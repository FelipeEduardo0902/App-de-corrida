import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import '../vm/run_vm.dart';
import '../../summary/run_summary_page.dart';
import '../../training/models/workout_plan.dart'; // ✅ plano de treino

class RunPage extends StatefulWidget {
  final WorkoutPlan? initialWorkout; // ✅ treino opcional vindo do plano

  const RunPage({super.key, this.initialWorkout});

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
  void initState() {
    super.initState();
    // ✅ Se veio um treino, carrega ele no VM (com nome e metas)
    if (widget.initialWorkout != null) {
      Future.microtask(() {
        final vm = context.read<RunVM>();
        vm.loadWorkoutPlan(widget.initialWorkout!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RunVM>();

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.initialWorkout?.name ?? "Corrida Livre",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 🌍 Mapa
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

          // 📊 Painel superior
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Se for treino pré-configurado, mostra nome e tipo
                if (widget.initialWorkout != null)
                  Card(
                    color: Colors.orange.shade800.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.initialWorkout!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Treino ${widget.initialWorkout!.type} • "
                            "${widget.initialWorkout!.totalDistance.toStringAsFixed(0)} m • "
                            "${widget.initialWorkout!.estimatedDuration.inMinutes} min",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Card(
                  color: Colors.black.withOpacity(0.85),
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
                        _metric("Veloc.", "${speed.toStringAsFixed(1)} km/h"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🎮 Controles inferiores
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                if (vm.isRunning && !vm.isPaused)
                  ElevatedButton.icon(
                    onPressed: vm.pause,
                    icon: const Icon(Icons.pause),
                    label: const Text("Pausar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade700,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                if (vm.isPaused)
                  ElevatedButton.icon(
                    onPressed: vm.resume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Retomar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                const SizedBox(height: 8),
                if (vm.isRunning || vm.isPaused)
                  ElevatedButton.icon(
                    onPressed: () async {
                      vm.pause();
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
                      backgroundColor: Colors.red.shade700,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _centralizarNoUsuario,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Centralizar no mapa"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    minimumSize: const Size(double.infinity, 48),
                  ),
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
