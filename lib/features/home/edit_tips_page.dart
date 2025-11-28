import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTipsPage extends StatefulWidget {
  const EditTipsPage({super.key});

  @override
  State<EditTipsPage> createState() => _EditTipsPageState();
}

class _EditTipsPageState extends State<EditTipsPage> {
  final _db = FirebaseFirestore.instance;
  final TextEditingController _tipsController = TextEditingController();
  bool _loading = false;

  final Map<String, bool> _selectedTips = {}; // id -> selected

  Future<void> _saveTips() async {
    final text = _tipsController.text.trim();
    if (text.isEmpty) return;

    final tips = text.split('\n').where((t) => t.trim().isNotEmpty).toList();

    setState(() => _loading = true);

    try {
      for (final tip in tips) {
        await _db.collection('feed').add({
          'titulo': tip.length > 50 ? tip.substring(0, 50) + '...' : tip,
          'descricao': tip,
          'data': Timestamp.now(),
        });
      }

      _tipsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${tips.length} dica(s) adicionada(s)!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Erro ao salvar dicas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar as dicas'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _loading = false);
  }

  Future<void> _deleteSingleTip(String id) async {
    await _db.collection('feed').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Dica removida com sucesso!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _deleteSelectedTips() async {
    final selectedIds = _selectedTips.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione pelo menos uma dica.")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir dicas selecionadas"),
        content: Text(
          "Tem certeza que deseja apagar ${selectedIds.length} dica(s)?",
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Apagar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final id in selectedIds) {
        await _db.collection('feed').doc(id).delete();
      }
      setState(() => _selectedTips.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Dicas selecionadas excluídas!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _editTip(String id, String oldText) async {
    final controller = TextEditingController(text: oldText);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Dica"),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Edite sua dica aqui...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await _db.collection('feed').doc(id).update({
                'descricao': controller.text.trim(),
                'titulo': controller.text.length > 50
                    ? controller.text.substring(0, 50) + '...'
                    : controller.text,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✏️ Dica atualizada com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciar Dicas"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: "Excluir selecionadas",
            onPressed: _deleteSelectedTips,
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
            child: Text(
              "📋 Dicas Salvas — selecione, edite ou exclua",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          // 🔹 Lista das dicas salvas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('feed')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text("Nenhuma dica criada ainda."),
                  );
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;
                    final descricao = d['descricao'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: _selectedTips[id] ?? false,
                          onChanged: (v) => setState(() {
                            _selectedTips[id] = v ?? false;
                          }),
                        ),
                        title: Text(
                          descricao,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blueGrey,
                              ),
                              onPressed: () => _editTip(id, descricao),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deleteSingleTip(id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "➕ Adicionar novas dicas (uma por linha):",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tipsController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText:
                        "Exemplo:\nAlongue-se antes de correr\nAumente o ritmo gradualmente\nMantenha-se hidratado",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _saveTips,
                  icon: const Icon(Icons.save),
                  label: Text(_loading ? "Salvando..." : "Salvar Dicas"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
