import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/workout.dart';
import '../services/workout_service.dart';
import '../../training/models/workout_plan.dart'; // ✅ Importa o plano de treino

class RunVM extends ChangeNotifier {
  final _workoutService = WorkoutService();

  Duration _elapsed = Duration.zero;
  double _distance = 0; // em metros
  Timer? _timer;
  Position? _lastPosition;
  StreamSubscription<Position>? _positionSub;

  final List<LatLng> _route = [];

  Duration get elapsed => _elapsed;
  double get distance => _distance;
  List<LatLng> get route => List.unmodifiable(_route);

  bool _running = false;
  bool get isRunning => _running;

  bool _paused = false;
  bool get isPaused => _paused;

  WorkoutPlan? _currentPlan;
  WorkoutPlan? get currentPlan => _currentPlan;

  /// 🔹 Reinicia o estado completamente
  void reset() {
    _timer?.cancel();
    _positionSub?.cancel();
    _elapsed = Duration.zero;
    _distance = 0;
    _lastPosition = null;
    _route.clear();
    _running = false;
    _paused = false;
    notifyListeners();
  }

  /// 🔹 Carrega um treino planejado
  void loadWorkoutPlan(WorkoutPlan plan) {
    reset();
    _currentPlan = plan;
    debugPrint(
      "🏋️ Treino carregado: ${plan.name} (${plan.steps.length} etapas)",
    );
    debugPrint("Distância total: ${plan.totalDistance.toStringAsFixed(0)} m");
    notifyListeners();
  }

  /// ▶️ Inicia corrida (livre ou com treino)
  Future<void> start() async {
    _elapsed = Duration.zero;
    _distance = 0;
    _route.clear();
    _running = true;
    _paused = false;
    notifyListeners();

    // cronômetro
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });

    // GPS ligado?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _running = false;
      notifyListeners();
      throw Exception("Ative o GPS do dispositivo para iniciar a corrida.");
    }

    // permissões
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      _running = false;
      notifyListeners();
      throw Exception("Permissão de localização permanentemente negada.");
    }
    if (perm == LocationPermission.denied) {
      _running = false;
      notifyListeners();
      throw Exception("Permissão de localização negada.");
    }

    // escuta GPS
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((pos) {
          if (_paused) return;

          final current = LatLng(pos.latitude, pos.longitude);

          if (_lastPosition != null) {
            final dist = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              pos.latitude,
              pos.longitude,
            );
            _distance += dist;
          }

          _lastPosition = pos;
          _route.add(current);
          notifyListeners();

          // 🔸 Se for um treino planejado, podemos detectar o fim de uma etapa futuramente aqui
        });
  }

  /// ⏸️ Pausa corrida
  void pause() {
    if (!_running) return;
    _paused = true;
    _timer?.cancel();
    _positionSub?.pause();
    notifyListeners();
  }

  /// ▶️ Retoma corrida
  void resume() {
    if (!_running || !_paused) return;
    _paused = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });

    _positionSub?.resume();
    notifyListeners();
  }

  /// 🏁 Finaliza e salva corrida no Firestore
  Future<void> stopAndSave() async {
    _timer?.cancel();
    _positionSub?.cancel();
    _running = false;
    _paused = false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final workout = Workout(
      id: const Uuid().v4(),
      date: DateTime.now(),
      distance: _distance,
      duration: _elapsed,
      route: List.of(_route),
    );

    await _workoutService.saveWorkout(workout, user.uid);
    notifyListeners();

    debugPrint("✅ Corrida salva com sucesso!");
  }

  /// 🗑️ Descartar corrida (sem salvar)
  void discard() {
    reset();
  }
}
