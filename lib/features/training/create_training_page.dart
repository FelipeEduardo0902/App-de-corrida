import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/workout_plan.dart';
import 'vm/training_vm.dart';
import 'save_training_page.dart';

class CreateTrainingPage extends StatefulWidget {
  const CreateTrainingPage({super.key});

  @override
  State<CreateTrainingPage> createState() => _CreateTrainingPageState();
}

class _CreateTrainingPageState extends State<CreateTrainingPage> {
  String? _selectedType;
  String? _goalType;
  double? _distance; // em km
  int? _duration; // em minutos
  String? _intensity;
  int? _repeats;

  double? _estimatedDistance;

  final _types = ["Aquecimento", "Corrida", "Descanso", "Desaquecimento"];
  final _goals = ["Distância", "Tempo"];
  final _intensities = ["Leve", "Moderado", "Forte"];
  final _repeatsList = List.generate(20, (i) => i + 1);

  void _openSelector<T>({
    required String title,
    required List<T> options,
    required void Function(T) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...options.map((opt) {
                return ListTile(
                  title: Center(
                    child: Text(
                      opt.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(opt);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _calculateEstimatedDistance() {
    if (_goalType == "Tempo" && _duration != null && _intensity != null) {
      final pace = switch (_intensity) {
        "Leve" => 6.5,
        "Moderado" => 5.5,
        "Forte" => 4.5,
        _ => 6.0,
      };
      final km = _duration! / pace;
      setState(() => _estimatedDistance = km);
    } else {
      setState(() => _estimatedDistance = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainingVM>();
    final totalKm = vm.totalDistance / 1000;
    final totalDuration = vm.totalDuration.inMinutes;
    final steps = vm.steps;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text(
          "Criar Treino",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 RESUMO DO TREINO
            Card(
              color: Colors.orange.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem(
                      Icons.directions_run,
                      "Etapas",
                      steps.length.toString(),
                    ),
                    _summaryItem(
                      Icons.route,
                      "Distância total",
                      "${totalKm.toStringAsFixed(2)} km",
                    ),
                    _summaryItem(
                      Icons.timer,
                      "Duração",
                      "${totalDuration.toStringAsFixed(0)} min",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 ETAPAS EXISTENTES
            if (steps.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 6.0,
                    ),
                    child: Text(
                      "Etapas adicionadas:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...steps.map(
                    (step) => Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.flag, color: Colors.orange),
                        ),
                        title: Text(
                          "${step.type.toUpperCase()} • ${step.intensityLabel}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          step.goalType == "distância"
                              ? "${(step.targetDistance / 1000).toStringAsFixed(2)} km × ${step.repeatCount}"
                              : "${step.targetDuration?.inMinutes ?? 0} min × ${step.repeatCount}",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => vm.removeStep(step),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),

            // 🔹 SELEÇÕES
            _buildCard(
              icon: Icons.directions_run,
              label: "Tipo de Etapa",
              value: _selectedType ?? "Selecionar",
              onTap: () => _openSelector(
                title: "Selecione o tipo de etapa",
                options: _types,
                onSelected: (v) => setState(() => _selectedType = v),
              ),
            ),
            _buildCard(
              icon: Icons.flag_circle_outlined,
              label: "Tipo de Meta",
              value: _goalType ?? "Selecionar",
              onTap: () => _openSelector(
                title: "Selecione o tipo de meta",
                options: _goals,
                onSelected: (v) {
                  setState(() {
                    _goalType = v;
                    _distance = null;
                    _duration = null;
                    _estimatedDistance = null;
                  });
                },
              ),
            ),

            if (_goalType == "Distância")
              _buildCard(
                icon: Icons.straighten,
                label: "Distância (km)",
                value: _distance != null
                    ? "${_distance!.toStringAsFixed(2)} km"
                    : "Selecionar",
                onTap: () => _openSelector(
                  title: "Selecione a distância (em km)",
                  options: List.generate(30, (i) => (i + 1) * 0.5),
                  onSelected: (v) => setState(() => _distance = v),
                ),
              ),

            if (_goalType == "Tempo")
              Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Duração (min)",
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Digite o tempo em minutos",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.orange.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.orange,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null) {
                            setState(() => _duration = parsed);
                            _calculateEstimatedDistance();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

            _buildCard(
              icon: Icons.fitness_center,
              label: "Intensidade",
              value: _intensity ?? "Selecionar",
              onTap: () => _openSelector(
                title: "Selecione a intensidade",
                options: _intensities,
                onSelected: (v) {
                  setState(() => _intensity = v);
                  _calculateEstimatedDistance();
                },
              ),
            ),

            if (_estimatedDistance != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(
                  "≈ Distância estimada: ${_estimatedDistance!.toStringAsFixed(2)} km",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            _buildCard(
              icon: Icons.repeat,
              label: "Repetições",
              value: _repeats != null ? "${_repeats}x" : "Selecionar",
              onTap: () => _openSelector(
                title: "Selecione o número de repetições",
                options: _repeatsList,
                onSelected: (v) => setState(() => _repeats = v),
              ),
            ),

            const SizedBox(height: 24),
            _buildAddStepButton(vm),
            const SizedBox(height: 16),
            _buildSavePlanButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String label, String value) {
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
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.orange.withOpacity(0.15),
                child: Icon(icon, color: Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

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
          targetDistance: (_distance ?? _estimatedDistance ?? 0) * 1000,
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
          _estimatedDistance = null;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

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
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
