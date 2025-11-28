import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  double totalKm = 0;
  int totalRuns = 0;
  double avgPace = 0;
  bool loadingStats = true;
  bool localeLoaded = false;

  String? profilePhoto;
  String username = "Runner";

  final List<Color> cardColors = [
    const Color(0xFFFFF3E0),
    const Color(0xFFE3F2FD),
    const Color(0xFFE8F5E9),
    const Color(0xFFF3E5F5),
    const Color(0xFFFFEBEE),
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocaleAndLoad();
    _loadUserInfo();
  }

  Future<void> _initializeLocaleAndLoad() async {
    try {
      await initializeDateFormatting('pt_BR', null);
      setState(() => localeLoaded = true);
      await _loadStats();
    } catch (e) {
      debugPrint("Erro ao inicializar locale: $e");
    }
  }

  Future<void> _loadUserInfo() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final data = doc.data() ?? {};

      setState(() {
        username = data["name"] ?? user!.email!.split('@')[0];
        profilePhoto = data["profilePhoto"];
      });
    } catch (e) {
      debugPrint("❌ Erro ao carregar dados do usuário: $e");
    }
  }

  Future<void> _loadStats() async {
    if (user == null) {
      setState(() => loadingStats = false);
      return;
    }

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user!.uid)
          .collection('workout_history')
          .get();

      double kmSum = 0;
      int count = snapshot.docs.length;
      double totalPaceSum = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final distance = (data['distance'] ?? 0).toDouble();
        final duration = (data['duration'] ?? 0).toInt();
        kmSum += distance / 1000;
        if (distance > 0) {
          totalPaceSum += (duration / 60) / (distance / 1000);
        }
      }

      setState(() {
        totalKm = kmSum;
        totalRuns = count;
        avgPace = count > 0 ? totalPaceSum / count : 0;
        loadingStats = false;
      });
    } catch (e) {
      debugPrint("❌ Erro ao carregar estatísticas: $e");
      setState(() => loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 2,
        title: const Text(
          "SafeRun",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Nenhuma notificação no momento")),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserInfo();
          await _loadStats();
        },
        child: !localeLoaded
            ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Cabeçalho com foto real
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: profilePhoto != null
                            ? NetworkImage(profilePhoto!)
                            : const AssetImage("assets/avatar_placeholder.png")
                                  as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Bem-vindo, $username 👋",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Estatísticas
                  if (loadingStats)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  else
                    Row(
                      children: [
                        _StatCard(
                          label: "Total KM",
                          value: totalKm.toStringAsFixed(1),
                        ),
                        const SizedBox(width: 12),
                        _StatCard(label: "Corridas", value: "$totalRuns"),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: "Pace Médio",
                          value: avgPace > 0
                              ? "${avgPace.toStringAsFixed(1)} min/km"
                              : "—",
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),

                  // Dicas de Treino
                  const Text(
                    "💡 Dicas de Treino e Motivação",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('feed')
                        .orderBy('data', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              "Nenhuma dica publicada ainda. Vá em Perfil → Gerenciar Dicas para adicionar!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return Column(
                        children: List.generate(docs.length, (i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          final titulo = d['titulo'] ?? '';
                          final descricao = d['descricao'] ?? '';
                          final data = (d['data'] as Timestamp).toDate();
                          final color = cardColors[i % cardColors.length];

                          final dataFormatada = toBeginningOfSentenceCase(
                            DateFormat(
                              "d 'de' MMMM 'de' yyyy",
                              'pt_BR',
                            ).format(data),
                          )!;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: Colors.orange,
                                  size: 26,
                                ),
                              ),
                              title: Text(
                                titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFFFC4C02),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      descricao,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "📅 $dataFormatada",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFC4C02),
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
