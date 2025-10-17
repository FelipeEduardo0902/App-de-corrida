import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/workout_plan.dart';
import 'vm/training_vm.dart';
import 'create_training_page.dart';

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
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Meus Treinos",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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
                "Nenhum treino salvo ainda.\nToque em + para criar um treino.",
                style: TextStyle(color: Colors.black54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.workouts.length,
              itemBuilder: (context, index) {
                final plan = vm.workouts[index];
                return _buildWorkoutCard(context, plan, vm);
              },
            ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    WorkoutPlan plan,
    TrainingVM vm,
  ) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.orange.shade100,
          child: const Icon(Icons.directions_run, color: Colors.orange),
        ),
        title: Text(
          plan.name,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        subtitle: Text(
          "${plan.steps.length} etapas • ${plan.totalDistance.toStringAsFixed(0)} m • ${plan.estimatedDuration.inMinutes} min",
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: "Iniciar treino",
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("🏃 Iniciando '${plan.name}'..."),
                    backgroundColor: Colors.green.shade600,
                  ),
                );
              },
            ),
            IconButton(
              tooltip: "Excluir treino",
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                await vm.deleteWorkout(plan.id);
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _WorkoutDetailPage(plan: plan)),
          );
        },
      ),
    );
  }
}

/// 🔹 Tela de detalhes do treino selecionado
class _WorkoutDetailPage extends StatelessWidget {
  final WorkoutPlan plan;
  const _WorkoutDetailPage({required this.plan});

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...plan.steps.asMap().entries.map((entry) {
            final i = entry.key + 1;
            final s = entry.value;
            final color = s.type == "corrida"
                ? Colors.orange
                : s.type == "aquecimento"
                ? Colors.green
                : s.type == "descanso"
                ? Colors.blue
                : Colors.purple;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Text(
                    "$i",
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  "${s.type.toUpperCase()} (${s.paceZone})",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "${s.intensityLabel} • "
                  "${s.goalType == 'tempo' ? '${s.targetDuration?.inMinutes ?? 0} min' : '${s.targetDistance.toStringAsFixed(0)} m'}"
                  "${s.repeatCount > 1 ? ' • Repetir ${s.repeatCount}x' : ''}",
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
