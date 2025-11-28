import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_profile_page.dart';
import 'settings_page.dart';
import '../home/edit_tips_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>> _getUserData() async {
    if (user == null) return {"name": "Usuário", "profilePhoto": null};

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final data = doc.data() ?? {};
      return {
        "name": data['name'] ?? "Usuário",
        "profilePhoto": data['profilePhoto'],
      };
    } catch (e) {
      debugPrint("❌ Erro ao buscar dados do usuário: $e");
      return {"name": "Usuário", "profilePhoto": null};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meu Perfil")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          final data = snapshot.data ?? {};
          final nome = data["name"] ?? "Usuário";
          final fotoUrl = data["profilePhoto"];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ Exibe foto real ou placeholder
                CircleAvatar(
                  radius: 60,
                  backgroundImage: fotoUrl != null
                      ? NetworkImage(fotoUrl)
                      : const AssetImage("assets/avatar_placeholder.png")
                            as ImageProvider,
                ),
                const SizedBox(height: 16),

                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // 🔹 Editar perfil
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Editar Perfil"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                    // 🔁 Recarrega dados após voltar do editar perfil
                    setState(() {});
                  },
                ),
                const Divider(),

                // 🔹 Configurações
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text("Configurações"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                const Divider(),

                // 🔹 Gerenciar Dicas
                ListTile(
                  leading: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                  ),
                  title: const Text("Gerenciar Dicas"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditTipsPage(),
                      ),
                    );
                  },
                ),
                const Divider(),

                const Spacer(),

                // 🔹 Logout
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Sair"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
