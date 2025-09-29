import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SafeRun"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Nenhuma notificação no momento")),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabeçalho
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage("assets/avatar_placeholder.png"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Bem-vindo, ${user?.email?.split('@')[0] ?? 'Runner'} 👋",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Estatísticas rápidas
          Row(
            children: const [
              _StatCard(label: "Total KM", value: "45.2"),
              SizedBox(width: 12),
              _StatCard(label: "Corridas", value: "12"),
              SizedBox(width: 12),
              _StatCard(label: "Pace Médio", value: "5:45"),
            ],
          ),
          const SizedBox(height: 30),

          // Feed de posts/dicas
          Text(
            "📢 Feed de Dicas",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),

          const _PostCard(
            title: "Alongamento é essencial",
            text:
                "Sempre alongue antes e depois da corrida para evitar lesões. 🚀",
          ),
          const _PostCard(
            title: "Hidrate-se sempre",
            text:
                "Beba água antes, durante e após o treino. Hidratação é performance. 💧",
          ),
          const _PostCard(
            title: "Varie os treinos",
            text:
                "Intercale corridas leves e treinos intensos para evoluir mais rápido. 🔥",
          ),
          const _PostCard(
            title: "Nutrição é chave",
            text:
                "Combine carboidratos e proteínas no pós-treino para melhor recuperação. 🍎",
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFC4C02), // Laranja principal
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

class _PostCard extends StatelessWidget {
  final String title;
  final String text;

  const _PostCard({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFC4C02),
              ),
            ),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
