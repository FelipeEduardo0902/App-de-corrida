import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';

class WorkoutService {
  final _db = FirebaseFirestore.instance;

  /// Salva corrida em `users/{uid}/workouts/{id}`
  Future<void> saveWorkout(Workout workout, String userId) async {
    await _db
        .collection("users")
        .doc(userId)
        .collection("workouts")
        .doc(workout.id)
        .set({
          "id": workout.id,
          "date": Timestamp.fromDate(workout.date),
          "distance": workout.distance,
          "duration": workout.duration.inSeconds,
          "route": workout.route
              .map((p) => {"lat": p.latitude, "lng": p.longitude})
              .toList(),
        });
  }

  /// Busca todas as corridas do usuário
  Future<List<Workout>> getWorkouts(String userId) async {
    final snapshot = await _db
        .collection("users")
        .doc(userId)
        .collection("workouts")
        .orderBy("date", descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data["id"] = doc.id;
      return Workout.fromMap(data);
    }).toList();
  }
}
