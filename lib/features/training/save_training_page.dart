import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/workout_plan.dart';
import 'vm/training_vm.dart';

class SaveTrainingPage extends StatefulWidget {
  const SaveTrainingPage({super.key});

  @override
  State<SaveTrainingPage> createState() => _SaveTrainingPageState();
}

class _SaveTrainingPageState extends State<SaveTrainingPage> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TrainingVM>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text(
          "Salvar Treino",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF7F7F7),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nome do Treino",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: "Tipo (ex: Intervalado, Longão...)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                "Salvar Treino Completo",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Informe o nome do treino.")),
                  );
                  return;
                }

                final plan = WorkoutPlan(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _nameController.text,
                  type: _typeController.text.isEmpty
                      ? "Personalizado"
                      : _typeController.text,
                  steps: vm.steps,
                );

                await vm.saveWorkout(plan);
                vm.clearSteps();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Treino salvo com sucesso!"),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
