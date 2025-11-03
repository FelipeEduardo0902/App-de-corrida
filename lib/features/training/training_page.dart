import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔹 Model e ViewModel do módulo de Treino
import 'models/workout_plan.dart';
import 'vm/training_vm.dart';
import 'create_training_page.dart';

// 🔹 Página de corrida (para iniciar treino)
import '../run/pages/run_page.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrainingVM>().loadWorkouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainingVM>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 2,
        title: const Text(
          "Meus Treinos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Criar Treino",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTrainingPage()),
          );
        },
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : vm.workouts.isEmpty
          ? const Center(
              child: Text(
                "🏋️ Nenhum treino criado ainda.\nToque em + para adicionar seu primeiro treino.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.workouts.length,
              itemBuilder: (context, i) {
                final plan = vm.workouts[i];
                return _workoutCard(context, plan, vm);
              },
            ),
    );
  }

  Widget _workoutCard(BuildContext context, WorkoutPlan plan, TrainingVM vm) {
    final totalKm = (plan.totalDistance / 1000).toStringAsFixed(2);
    final totalMin = plan.estimatedDuration.inMinutes;

    return Card(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Cabeçalho do treino
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.orange.withOpacity(0.15),
                  child: const Icon(Icons.fitness_center, color: Colors.orange),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${plan.steps.length} etapas • $totalKm km • $totalMin min",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Excluir treino",
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async {
                    final confirm = await _confirmDelete(context, plan.name);
                    if (confirm == true) {
                      await vm.deleteWorkout(plan.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Treino '${plan.name}' excluído com sucesso.",
                            ),
                            backgroundColor: Colors.red.shade400,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 18),

            // 🔹 Ações
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.type,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _WorkoutDetailPage(plan: plan),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline, size: 20),
                      label: const Text("Detalhes"),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Iniciar",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("🏃 Iniciando '${plan.name}'..."),
                            backgroundColor: Colors.green.shade700,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RunPage(initialWorkout: plan),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Diálogo de confirmação de exclusão
  Future<bool?> _confirmDelete(BuildContext context, String treinoNome) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          "Excluir treino",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Tem certeza que deseja excluir '$treinoNome'?",
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text(
              "Excluir",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutDetailPage extends StatelessWidget {
  final WorkoutPlan plan;
  const _WorkoutDetailPage({required this.plan});

  @override
  Widget build(BuildContext context) {
    final totalKm = (plan.totalDistance / 1000).toStringAsFixed(2);
    final totalMin = plan.estimatedDuration.inMinutes;
    final avgPace = totalKm != "0.00"
        ? (totalMin / double.parse(totalKm)).toStringAsFixed(1)
        : "0.0";

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(plan.name, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔹 Resumo do treino
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric("Distância", "$totalKm km"),
                _metric("Duração", "$totalMin min"),
                _metric("Pace", "$avgPace min/km"),
              ],
            ),
          ),

          // 🔹 Lista de etapas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plan.steps.length,
              itemBuilder: (_, i) {
                final step = plan.steps[i];
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
                  color: Colors.grey.shade900,
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Text(
                        "${i + 1}",
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
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      "${step.intensityLabel} • "
                      "${step.goalType == 'tempo' ? '$durationMin min' : '$distanceKm km'}"
                      "${step.repeatCount > 1 ? ' ×${step.repeatCount}' : ''}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
          ),

          // 🔹 Botão de iniciar corrida
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text(
                "Iniciar Corrida",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
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

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
