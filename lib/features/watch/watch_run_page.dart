import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart';

class WatchRunPage extends StatefulWidget {
  const WatchRunPage({super.key});

  @override
  State<WatchRunPage> createState() => _WatchRunPageState();
}

class _WatchRunPageState extends State<WatchRunPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<LatLng> _route = [];
  bool _isRunning = false;
  double _distance = 0;
  DateTime? _startTime;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTTS();
    _checkPermissionAndLocate();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage("pt-BR");
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _checkPermissionAndLocate() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _tts.speak("Por favor, ative o GPS do relógio.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _tts.speak("Permita o acesso à localização para continuar.");
        return;
      }
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    setState(() => _currentPosition = pos);

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 17),
      );
    }
  }

  Future<void> _toggleRun() async {
    if (_isRunning) {
      // Finaliza o treino
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]);
      }
      await _tts.speak("Treino finalizado. Bom trabalho!");

      setState(() {
        _isRunning = false;
        _startTime = null;
      });
      return;
    }

    // Inicia o treino
    await _tts.speak("Iniciando treino");
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 150);
    }

    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
      _route.clear();
      _distance = 0;
    });

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!_isRunning) return;
      setState(() {
        if (_route.isNotEmpty) {
          final last = _route.last;
          final segment = Geolocator.distanceBetween(
            last.latitude,
            last.longitude,
            pos.latitude,
            pos.longitude,
          );
          _distance += segment;
        }
        _route.add(LatLng(pos.latitude, pos.longitude));
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🗺️ Mapa com rota
          if (_currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 17,
              ),
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              mapType: MapType.normal,
              polylines: {
                if (_route.isNotEmpty)
                  Polyline(
                    polylineId: const PolylineId("rota"),
                    points: _route,
                    color: Colors.orangeAccent,
                    width: 5,
                  ),
              },
              onMapCreated: (controller) => _mapController = controller,
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),

          // 🏃 Dados e botão de iniciar/parar
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isRunning)
                    Column(
                      children: [
                        Text(
                          "${(_distance / 1000).toStringAsFixed(2)} km",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${DateTime.now().difference(_startTime!).inMinutes} min",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _toggleRun,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning
                          ? Colors.redAccent
                          : Colors.orange,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(22),
                    ),
                    child: Icon(
                      _isRunning ? Icons.stop : Icons.play_arrow,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
