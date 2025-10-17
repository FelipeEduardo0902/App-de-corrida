import 'package:flutter/material.dart';
import '../run/run_page.dart'; // ✅ importa a tela de corrida
import 'models/workout_plan.dart';

class TrainingDetailPage extends StatelessWidget {
  final WorkoutPlan plan;
  const TrainingDetailPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
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
          // 🔹 Cabeçalho com resumo do treino
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 8),
                    Text(
                      "${plan.steps.length} etapas • ${plan.totalDistance.toStringAsFixed(0)} m • ${plan.estimatedDuration.inMinutes} min",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Tipo: ${plan.type}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
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

          // 🔹 Lista de etapas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
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
                      "${step.goalType == 'tempo' ? '${step.targetDuration?.inMinutes ?? 0} min' : '${step.targetDistance.toStringAsFixed(0)} m'}"
                      "${step.repeatCount > 1 ? ' • Repetir ${step.repeatCount}x' : ''}",
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
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
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
}
