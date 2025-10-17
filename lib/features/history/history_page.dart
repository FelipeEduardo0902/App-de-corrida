import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'vm/history_vm.dart'; // ViewModel
import '../run/models/workout.dart'; // Modelo
import '../run/services/workout_service.dart'; // Serviço (acesso Firestore)
import 'workout_detail_page.dart'; // Detalhes da corrida
import '../../core/utils/formatters.dart'; // Funções utilitárias

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
      appBar: AppBar(
        title: const Text("Histórico de Corridas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 2,
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(HistoryVM vm) {
    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null) {
      return Center(child: Text(vm.error!));
    }

    if (vm.workouts.isEmpty) {
      return const Center(
        child: Text(
          "Nenhuma corrida registrada.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // 🔹 Agrupa corridas por data (dd/MM/yyyy)
    final grouped = <String, List<Workout>>{};
    for (final w in vm.workouts) {
      final key =
          "${w.date.day.toString().padLeft(2, '0')}/${w.date.month.toString().padLeft(2, '0')}/${w.date.year}";
      grouped.putIfAbsent(key, () => []).add(w);
    }

    // 🔹 Ordena datas (mais recentes primeiro)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: sortedKeys.length,
      itemBuilder: (context, i) {
        final dateKey = sortedKeys[i];
        final workoutsOfDay = grouped[dateKey]!;

        // 🔹 Calcula total do dia (opcional)
        final totalKm = workoutsOfDay.fold<double>(
          0,
          (sum, w) => sum + w.distance / 1000,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com data e total de km
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6, left: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateKey,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  Text(
                    "${totalKm.toStringAsFixed(2)} km",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de corridas do dia
            ...workoutsOfDay.map((w) {
              final km = (w.distance / 1000).toStringAsFixed(2);
              final pace = w.distance > 0
                  ? (w.duration.inMinutes / (w.distance / 1000))
                        .toStringAsFixed(2)
                  : "0.0";
              final time =
                  "${w.date.hour.toString().padLeft(2, '0')}:${w.date.minute.toString().padLeft(2, '0')}";

              return Card(
                elevation: 3,
                shadowColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.directions_run, color: Colors.white),
                  ),
                  title: Text(
                    "$km km",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "Ritmo: $pace min/km | Duração: ${formatDuration(w.duration)}",
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Text(
                    time,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutDetailPage(workout: w),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
