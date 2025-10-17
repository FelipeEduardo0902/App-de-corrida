import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import '../../../core/theme/theme_provider.dart'; // 🔥 importa o provider global

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Configurações")),
      body: ListView(
        children: [
          // 🌙 Tema escuro global
          SwitchListTile(
            title: const Text("Tema escuro"),
            value: themeProvider.isDark, // usa o provider global
            onChanged: (val) {
              themeProvider.toggleTheme(val); // muda o tema do app todo
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    val ? "Tema escuro ativado" : "Tema claro ativado",
                  ),
                ),
              );
            },
          ),
          const Divider(),

          // 🔔 Notificações (mantém local por enquanto)
          SwitchListTile(
            title: const Text("Notificações"),
            value: true,
            onChanged: (val) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    val ? "Notificações ativadas" : "Notificações desativadas",
                  ),
                ),
              );
            },
          ),
          const Divider(),

          // 📍 Botão para abrir configurações de localização
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.orange),
            title: const Text("Permissão de Localização"),
            subtitle: const Text("Abrir configurações do app"),
            onTap: () {
              AppSettings.openAppSettings(type: AppSettingsType.location);
            },
          ),
        ],
      ),
    );
  }
}
