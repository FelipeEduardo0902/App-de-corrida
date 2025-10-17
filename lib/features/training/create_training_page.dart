import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/workout_plan.dart';
import 'vm/training_vm.dart';
import 'save_training_page.dart'; // 👈 nova tela para nomear e salvar treino

class CreateTrainingPage extends StatefulWidget {
  const CreateTrainingPage({super.key});

  @override
  State<CreateTrainingPage> createState() => _CreateTrainingPageState();
}

class _CreateTrainingPageState extends State<CreateTrainingPage> {
  String? _selectedType;
  String? _goalType;
  double? _distance;
  int? _duration;
  String? _intensity;
  int? _repeats;

  final _types = ["Aquecimento", "Corrida", "Descanso", "Desaquecimento"];
  final _goals = ["Distância", "Tempo"];
  final _intensities = ["Leve", "Moderado", "Forte"];

  final _distances = List.generate(100, (i) => (i + 1) * 100.0);
  final _durations = List.generate(60, (i) => i + 1);
  final _repeatsList = List.generate(20, (i) => i + 1);

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TrainingVM>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text(
          "Criar Treino Personalizado",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildSection(
              label: "Tipo de Etapa",
              child: _buildWheel(
                items: _types,
                selected: _selectedType,
                onSelected: (v) => setState(() => _selectedType = v),
              ),
            ),
            _buildSection(
              label: "Tipo de Meta",
              child: _buildWheel(
                items: _goals,
                selected: _goalType,
                onSelected: (v) => setState(() => _goalType = v),
              ),
            ),
            if (_goalType == "Distância")
              _buildSection(
                label: "Distância (m)",
                child: _buildWheelNum(
                  items: _distances,
                  selected: _distance,
                  onSelected: (v) => setState(() => _distance = v),
                ),
              ),
            if (_goalType == "Tempo")
              _buildSection(
                label: "Duração (min)",
                child: _buildWheelNum(
                  items: _durations.map((e) => e.toDouble()).toList(),
                  selected: _duration?.toDouble(),
                  onSelected: (v) => setState(() => _duration = v.toInt()),
                ),
              ),
            _buildSection(
              label: "Intensidade",
              child: _buildWheel(
                items: _intensities,
                selected: _intensity,
                onSelected: (v) => setState(() => _intensity = v),
              ),
            ),
            _buildSection(
              label: "Repetições",
              child: _buildWheelNum(
                items: _repeatsList.map((e) => e.toDouble()).toList(),
                selected: _repeats?.toDouble(),
                onSelected: (v) => setState(() => _repeats = v.toInt()),
              ),
            ),
            const SizedBox(height: 30),
            _buildAddStepButton(vm),
            const SizedBox(height: 14),
            _buildSavePlanButton(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String label, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(height: 90, child: child),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required List<String> items,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    final controller = FixedExtentScrollController(
      initialItem: selected != null ? items.indexOf(selected) : 0,
    );
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 40,
      diameterRatio: 1.2,
      onSelectedItemChanged: (i) => onSelected(items[i]),
      physics: const FixedExtentScrollPhysics(),
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (context, index) {
          final isSelected = items[index] == selected;
          return AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: isSelected ? Colors.orange : Colors.black45,
              fontSize: isSelected ? 20 : 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            child: Center(child: Text(items[index])),
          );
        },
        childCount: items.length,
      ),
    );
  }

  Widget _buildWheelNum({
    required List<double> items,
    required double? selected,
    required ValueChanged<double> onSelected,
  }) {
    final controller = FixedExtentScrollController(
      initialItem: selected != null ? items.indexOf(selected) : 0,
    );
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 40,
      diameterRatio: 1.2,
      onSelectedItemChanged: (i) => onSelected(items[i]),
      physics: const FixedExtentScrollPhysics(),
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (context, index) {
          final isSelected = items[index] == selected;
          return AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: isSelected ? Colors.orange : Colors.black45,
              fontSize: isSelected ? 20 : 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            child: Center(child: Text("${items[index].toInt()}")),
          );
        },
        childCount: items.length,
      ),
    );
  }

  // ➕ Botão para adicionar nova etapa
  Widget _buildAddStepButton(TrainingVM vm) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
      label: const Text(
        "Adicionar Etapa",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onPressed: () async {
        if (_selectedType == null ||
            _goalType == null ||
            _intensity == null ||
            _repeats == null ||
            ((_goalType == "Distância" && _distance == null) ||
                (_goalType == "Tempo" && _duration == null))) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Preencha todos os campos antes de adicionar."),
            ),
          );
          return;
        }

        final step = TrainingStep(
          type: _selectedType!.toLowerCase(),
          goalType: _goalType!.toLowerCase(),
          targetDistance: _distance ?? 0,
          targetDuration: _duration != null
              ? Duration(minutes: _duration!)
              : null,
          intensityLabel: _intensity!,
          repeatCount: _repeats!,
          paceZone: _intensity == "Leve"
              ? "Z1"
              : _intensity == "Moderado"
              ? "Z3"
              : "Z4",
        );

        await vm.addStep(step);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Etapa adicionada com sucesso!")),
        );
        setState(() {
          _selectedType = null;
          _goalType = null;
          _distance = null;
          _duration = null;
          _intensity = null;
          _repeats = null;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // 💾 Botão para salvar treino completo
  Widget _buildSavePlanButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.done_all, color: Colors.white),
      label: const Text(
        "Salvar Treino Completo",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SaveTrainingPage()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey.shade700,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
