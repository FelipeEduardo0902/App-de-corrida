import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  List<Map<String, dynamic>> feedPosts = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadFeed();
  }

  Future<void> _loadStats() async {
    if (user == null) return;
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
        final duration = (data['duration'] ?? 0).toInt(); // segundos
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
    }
  }

  Future<void> _loadFeed() async {
    try {
      final snapshot = await _db.collection('feed_posts').get();
      setState(() {
        feedPosts = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      debugPrint("❌ Erro ao carregar feed: $e");
    }
  }

  Future<void> _addPost() async {
    final titleController = TextEditingController();
    final textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Adicionar nova dica 🏃‍♂️"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Título"),
            ),
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: "Conteúdo"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  textController.text.isNotEmpty) {
                await _db.collection('feed_posts').add({
                  'title': titleController.text,
                  'text': textController.text,
                  'createdAt': Timestamp.now(),
                });
                Navigator.pop(context);
                _loadFeed();
              }
            },
            child: const Text("Salvar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String id) async {
    await _db.collection('feed_posts').doc(id).delete();
    _loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    final username = user?.email?.split('@')[0] ?? 'Runner';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 2,
        title: const Text(
          "SafeRun Dashboard",
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _addPost,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Cabeçalho do usuário
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage("assets/avatar_placeholder.png"),
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

          // 🔹 Estatísticas de corrida
          if (loadingStats)
            const Center(child: CircularProgressIndicator(color: Colors.orange))
          else
            Row(
              children: [
                _StatCard(label: "Total KM", value: totalKm.toStringAsFixed(1)),
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

          // 🔹 Feed de dicas
          const Text(
            "📢 Feed de Dicas",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          if (feedPosts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Nenhuma dica publicada ainda.",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...feedPosts.map(
              (p) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 1,
                child: ListTile(
                  title: Text(
                    p['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFC4C02),
                    ),
                  ),
                  subtitle: Text(
                    p['text'] ?? '',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deletePost(p['id']),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 🔹 Widget simples de estatísticas
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
