import 'package:flutter/foundation.dart';
import '../../run/models/workout.dart';
import '../../run/services/workout_service.dart';

class HistoryVM extends ChangeNotifier {
  final _service = WorkoutService();

  List<Workout> workouts = [];
  bool loading = false;
  String? error;

  Future<void> loadHistory(String userId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      workouts = await _service.getWorkouts(userId);
    } catch (e) {
      error = "Erro ao carregar histórico: $e";
      workouts = [];
    }

    loading = false;
    notifyListeners();
  }
}
