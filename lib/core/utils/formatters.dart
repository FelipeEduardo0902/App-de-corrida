import 'package:intl/intl.dart';

/// Formata uma data e hora legível (ex: 06/10/2025 14:35)
String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy HH:mm').format(date);
}

/// Formata duração em hh:mm:ss
String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
  } else {
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }
}

/// Formata pace (min/km) baseado em distância e tempo
String formatPace(double distanceMeters, Duration duration) {
  if (distanceMeters <= 0) return "--";
  final km = distanceMeters / 1000;
  final paceSeconds = duration.inSeconds / km;
  final minutes = (paceSeconds ~/ 60).toString().padLeft(2, "0");
  final seconds = (paceSeconds % 60).toInt().toString().padLeft(2, "0");
  return "$minutes:$seconds /km";
}
