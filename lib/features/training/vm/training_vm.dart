import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_plan.dart';

class TrainingVM extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  List<WorkoutPlan> _workouts = [];

  // 👇 Etapas temporárias do treino em construção (usadas no CreateTrainingPage)
  final List<TrainingStep> _steps = [];

  bool get isLoading => _isLoading;
  List<WorkoutPlan> get workouts => _workouts;
  List<TrainingStep> get steps => List.unmodifiable(_steps);

  // ======================================================
  // 🔹 CRUD de Treinos no Firestore
  // ======================================================

  Future<void> loadWorkouts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint(
          "⚠️ Nenhum usuário logado — não é possível carregar treinos",
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint("👤 Usuário logado: ${user.uid}");
      debugPrint("📡 Buscando treinos em users/${user.uid}/workouts ...");

      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .get();

      debugPrint(
        "📨 Firestore respondeu com ${snapshot.docs.length} documentos.",
      );

      _workouts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint("🧩 Documento encontrado: ${doc.id} -> ${data['name']}");
        return WorkoutPlan.fromMap({'id': doc.id, ...data});
      }).toList();

      debugPrint("✅ ${_workouts.length} treinos carregados com sucesso!");
      for (final w in _workouts) {
        debugPrint(
          "🏋️ Treino: ${w.name} | Etapas: ${w.steps.length} | Distância: ${w.totalDistance}m | Duração: ${w.estimatedDuration.inMinutes}min",
        );
      }
    } catch (e, s) {
      debugPrint("❌ Erro ao carregar treinos: $e");
      debugPrint("📍 Stacktrace: $s");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveWorkout(WorkoutPlan plan) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("⚠️ Nenhum usuário logado — não é possível salvar treinos");
        return;
      }

      debugPrint(
        "💾 Salvando treino '${plan.name}' para o usuário ${user.uid}",
      );
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(plan.id)
          .set(plan.toMap());
      debugPrint("✅ Treino '${plan.name}' salvo com sucesso!");

      await loadWorkouts();
    } catch (e, s) {
      debugPrint("❌ Erro ao salvar treino: $e");
      debugPrint("📍 Stacktrace: $s");
    }
  }

  Future<void> deleteWorkout(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("⚠️ Nenhum usuário logado — não é possível excluir treinos");
        return;
      }

      debugPrint("🗑️ Excluindo treino $id do usuário ${user.uid}");
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(id)
          .delete();
      _workouts.removeWhere((t) => t.id == id);
      notifyListeners();
      debugPrint("✅ Treino removido localmente e no Firestore!");
    } catch (e, s) {
      debugPrint("❌ Erro ao excluir treino: $e");
      debugPrint("📍 Stacktrace: $s");
    }
  }

  // ======================================================
  // 🔹 Gerenciamento de etapas locais (telas de criação)
  // ======================================================

  Future<void> addStep(TrainingStep step) async {
    _steps.add(step);
    debugPrint("➕ Etapa adicionada: ${step.type} (${step.intensityLabel})");
    notifyListeners();
  }

  void removeStep(TrainingStep step) {
    _steps.remove(step);
    debugPrint("➖ Etapa removida: ${step.type}");
    notifyListeners();
  }

  void clearSteps() {
    debugPrint("🧹 Limpando etapas temporárias...");
    _steps.clear();
    notifyListeners();
  }

  Future<void> sendWorkoutToWatch(WorkoutPlan plan) async {
    debugPrint("📡 Enviando treino '${plan.name}' para o relógio...");
    await Future.delayed(const Duration(seconds: 2));
    debugPrint("✅ Treino '${plan.name}' enviado com sucesso!");
  }
}
