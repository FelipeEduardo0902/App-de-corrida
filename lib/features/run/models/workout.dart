import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Workout {
  final String id;
  final DateTime date;
  final double distance; // em metros
  final Duration duration;
  final List<LatLng> route;

  Workout({
    required this.id,
    required this.date,
    required this.distance,
    required this.duration,
    required this.route,
  });

  /// 🔹 Converte para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "date": Timestamp.fromDate(date), // ✅ Timestamp compatível com Firestore
      "distance": distance,
      "duration": duration.inSeconds,
      "route": route.isNotEmpty
          ? route.map((p) => {"lat": p.latitude, "lng": p.longitude}).toList()
          : [], // ✅ nunca nulo
    };
  }

  /// 🔹 Constrói a partir de Map (ao ler do Firestore)
  factory Workout.fromMap(Map<String, dynamic> map) {
    // ✅ converte 'date' mesmo que venha como Timestamp ou String
    DateTime parsedDate;
    if (map["date"] is Timestamp) {
      parsedDate = (map["date"] as Timestamp).toDate();
    } else if (map["date"] is String) {
      parsedDate = DateTime.parse(map["date"]);
    } else {
      parsedDate = DateTime.now();
    }

    // ✅ converte a lista de coordenadas, mesmo se for nula
    final routeData = map["route"];
    final List<LatLng> routeList = (routeData is List)
        ? routeData
              .map(
                (p) => LatLng(
                  (p["lat"] as num).toDouble(),
                  (p["lng"] as num).toDouble(),
                ),
              )
              .toList()
        : [];

    return Workout(
      id: map["id"] ?? "",
      date: parsedDate,
      distance: (map["distance"] as num?)?.toDouble() ?? 0.0,
      duration: Duration(seconds: (map["duration"] as num?)?.toInt() ?? 0),
      route: routeList, // ✅ nunca null
    );
  }
}
