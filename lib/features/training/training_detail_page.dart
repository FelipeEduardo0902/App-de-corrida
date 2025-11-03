import 'package:flutter/material.dart';
import '../run/pages/run_page.dart';
import 'models/workout_plan.dart';

class TrainingDetailPage extends StatelessWidget {
  final WorkoutPlan plan;
  const TrainingDetailPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final totalKm = (plan.totalDistance / 1000).toStringAsFixed(2);
    final totalMin = plan.estimatedDuration.inMinutes;
    final avgPace = plan.totalDistance > 0
        ? (totalMin / (plan.totalDistance / 1000))
        : 0.0;
    final paceStr = avgPace > 0 ? "${avgPace.toStringAsFixed(1)} min/km" : "—";

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          plan.name,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔹 Cabeçalho com resumo visual
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Resumo do Treino",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metric("Distância", "$totalKm km", Icons.route),
                      _metric("Duração", "$totalMin min", Icons.timer_outlined),
                      _metric("Pace", paceStr, Icons.directions_run),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Tipo: ${plan.type}",
                    style: const TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                  Text(
                    "Etapas: ${plan.steps.length}",
                    style: const TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Etapas do Treino",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // 🔹 Lista de etapas detalhada
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: plan.steps.length,
              itemBuilder: (context, index) {
                final step = plan.steps[index];
                final color = step.type == "corrida"
                    ? Colors.orange
                    : step.type == "aquecimento"
                    ? Colors.green
                    : step.type == "descanso"
                    ? Colors.blue
                    : Colors.purple;

                final distanceKm = (step.targetDistance / 1000).toStringAsFixed(
                  2,
                );
                final durationMin = step.targetDuration?.inMinutes ?? 0;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      step.type.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      "${step.intensityLabel} • "
                      "${step.goalType == 'tempo' ? '$durationMin min' : '$distanceKm km'}"
                      "${step.repeatCount > 1 ? ' • Repetir ${step.repeatCount}x' : ''}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
          ),

          // 🔹 Botão "Iniciar Corrida"
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text(
                "Iniciar Corrida",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RunPage(initialWorkout: plan),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 22),
        const SizedBox(height: 4),
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
}
