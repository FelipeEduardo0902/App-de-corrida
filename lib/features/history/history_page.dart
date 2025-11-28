import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import 'vm/history_vm.dart';
import '../run/models/workout.dart';
import '../run/services/workout_service.dart';
import '../../core/utils/formatters.dart';
import '../run/pages/run_detail_page.dart'; // ✅ nova tela de mapa detalhado

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await context.read<HistoryVM>().loadHistory(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryVM>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        title: const Text(
          "Histórico de Corridas",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(HistoryVM vm) {
    if (vm.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (vm.error != null) {
      return Center(child: Text(vm.error!));
    }

    if (vm.workouts.isEmpty) {
      return const Center(
        child: Text(
          "🏃 Nenhuma corrida registrada ainda.\nComece uma para ver seu histórico aqui!",
          style: TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      );
    }

    // 🔹 Agrupa corridas por data real
    final grouped = <DateTime, List<Workout>>{};
    for (final w in vm.workouts) {
      final date = DateTime(w.date.year, w.date.month, w.date.day);
      grouped.putIfAbsent(date, () => []).add(w);
    }

    // 🔹 Ordena da mais recente para a mais antiga
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // mais recentes primeiro

    // 🔹 Estatísticas gerais
    final totalRuns = vm.workouts.length;
    final totalKm = vm.workouts.fold<double>(
      0,
      (sum, w) => sum + w.distance / 1000,
    );
    final totalTime = vm.workouts.fold<int>(
      0,
      (sum, w) => sum + w.duration.inMinutes,
    );
    final avgPace = totalKm > 0 ? totalTime / totalKm : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 🔹 Resumo geral do histórico
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric("Corridas", "$totalRuns", Icons.directions_run),
                _metric(
                  "Distância",
                  "${totalKm.toStringAsFixed(1)} km",
                  Icons.route,
                ),
                _metric(
                  "Pace médio",
                  "${avgPace.toStringAsFixed(1)} min/km",
                  Icons.timer_outlined,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 🔹 Lista agrupada por data
        ...sortedDates.map((date) {
          final workoutsOfDay = grouped[date]!;
          final dateKey =
              "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
          final totalKmDay = workoutsOfDay.fold<double>(
            0,
            (sum, w) => sum + w.distance / 1000,
          );

          // 🔹 Cabeçalho da data
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 8, left: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateKey,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "${totalKmDay.toStringAsFixed(2)} km",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Corridas desse dia
              ...workoutsOfDay.map((w) {
                final km = (w.distance / 1000).toStringAsFixed(2);
                final pace = w.distance > 0
                    ? (w.duration.inMinutes / (w.distance / 1000))
                          .toStringAsFixed(1)
                    : "0.0";
                final time =
                    "${w.date.hour.toString().padLeft(2, '0')}:${w.date.minute.toString().padLeft(2, '0')}";

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_run,
                        color: Colors.orange,
                        size: 26,
                      ),
                    ),
                    title: Text(
                      "$km km em ${formatDuration(w.duration)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      "Ritmo médio: $pace min/km",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Text(
                      time,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RunDetailPage(workout: w),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _metric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }
}
