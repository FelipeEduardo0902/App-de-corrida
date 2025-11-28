import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class ExportDataPage extends StatefulWidget {
  const ExportDataPage({super.key});

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  final _db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  bool loading = false;
  String exportText = "";
  bool exported = false;

  Future<void> _exportData() async {
    setState(() => loading = true);

    try {
      final uid = user!.uid;

      // 🔹 Histórico de corridas
      final historySnap = await _db
          .collection('users')
          .doc(uid)
          .collection('workout_history')
          .get();

      final workouts = historySnap.docs.map((d) {
        final data = d.data();
        data.updateAll((key, value) {
          if (value is Timestamp) return value.toDate().toIso8601String();
          return value;
        });
        return data;
      }).toList();

      // 🔹 Feed de dicas
      final feedSnap = await _db.collection('feed').get();
      final feed = feedSnap.docs.map((d) {
        final data = d.data();
        data.updateAll((key, value) {
          if (value is Timestamp) return value.toDate().toIso8601String();
          return value;
        });
        return data;
      }).toList();

      final data = {
        "usuario": user!.email,
        "exportado_em": DateTime.now().toIso8601String(),
        "treinos": workouts,
        "dicas": feed,
      };

      final jsonData = const JsonEncoder.withIndent('  ').convert(data);

      setState(() {
        exportText = jsonData;
        exported = true;
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Dados exportados com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("❌ Erro ao exportar dados: $e");
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao exportar dados."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareData() async {
    if (exportText.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      exportText,
      subject: 'Exportação de dados SafeRun',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📤 Dados compartilhados com sucesso!"),
          backgroundColor: Colors.blue,
        ),
      );

      // ✅ Só volta pro Dashboard após compartilhar
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exportar Dados"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: loading ? null : _exportData,
              icon: const Icon(Icons.cloud_download),
              label: const Text("Gerar Exportação"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            if (loading)
              const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
            else if (exportText.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      exportText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  "Clique em 'Gerar Exportação' para visualizar seus dados de treino e dicas.",
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 12),

            if (exported)
              ElevatedButton.icon(
                onPressed: _shareData,
                icon: const Icon(Icons.share),
                label: const Text("Compartilhar e Finalizar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
