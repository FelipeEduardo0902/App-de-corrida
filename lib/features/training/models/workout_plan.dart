import 'package:flutter/material.dart';

class TrainingStep {
  final String type; // corrida, descanso, aquecimento, desaquecimento
  final double targetDistance; // em metros
  final Duration? targetDuration; // duração alvo (opcional)
  final double? targetPace; // min/km
  final String paceZone; // Z1, Z2, Z3, Z4, etc.
  final String intensityLabel; // LEVE, MODERADO, FORTE
  final int repeatCount; // número de repetições
  final String goalType; // "distancia" ou "tempo"
  final String? description; // texto livre para exibição

  TrainingStep({
    required this.type,
    required this.targetDistance,
    this.targetDuration,
    this.targetPace,
    this.paceZone = "Z1",
    this.intensityLabel = "LEVE",
    this.repeatCount = 1,
    this.goalType = "distancia",
    this.description,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'targetDistance': targetDistance,
    'targetDuration': targetDuration?.inSeconds,
    'targetPace': targetPace,
    'paceZone': paceZone,
    'intensityLabel': intensityLabel,
    'repeatCount': repeatCount,
    'goalType': goalType,
    'description': description,
  };

  factory TrainingStep.fromMap(Map<String, dynamic> map) {
    return TrainingStep(
      type: map['type'] ?? '',
      targetDistance: (map['targetDistance'] ?? 0).toDouble(),
      targetDuration: map['targetDuration'] != null
          ? Duration(
              seconds: map['targetDuration'] is int
                  ? map['targetDuration']
                  : int.tryParse(map['targetDuration'].toString()) ?? 0,
            )
          : null,
      targetPace: (map['targetPace'] as num?)?.toDouble(),
      paceZone: map['paceZone'] ?? 'Z1',
      intensityLabel: map['intensityLabel'] ?? 'LEVE',
      repeatCount: (map['repeatCount'] is int)
          ? map['repeatCount']
          : int.tryParse(map['repeatCount']?.toString() ?? '1') ?? 1,
      goalType: map['goalType'] ?? 'distancia',
      description: map['description'],
    );
  }
}

class WorkoutPlan {
  final String id;
  final String name;
  final String type; // Ex: Intervalado, Ritmo, Longão
  final List<TrainingStep> steps;

  WorkoutPlan({
    required this.id,
    required this.name,
    required this.steps,
    this.type = "Intervalado",
  });

  double get totalDistance =>
      steps.fold(0.0, (sum, e) => sum + (e.targetDistance * e.repeatCount));

  Duration get estimatedDuration => steps.fold(
    Duration.zero,
    (sum, e) => sum + ((e.targetDuration ?? Duration.zero) * e.repeatCount),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'steps': steps.map((e) => e.toMap()).toList(),
  };

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    final rawSteps = map['steps'];

    List<TrainingStep> parsedSteps = [];
    if (rawSteps != null && rawSteps is List) {
      parsedSteps = rawSteps
          .map((e) => TrainingStep.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      debugPrint("⚠️ Treino '${map['name']}' não possui steps válidos.");
    }

    return WorkoutPlan(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Treino sem nome',
      type: map['type'] ?? 'Intervalado',
      steps: parsedSteps,
    );
  }
}
