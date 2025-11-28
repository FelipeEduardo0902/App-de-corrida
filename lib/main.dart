import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

// Firebase
import 'firebase_options.dart';

// Tema
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

// Auth
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'features/auth/pages/reset_password_page.dart';

// Home
import 'features/home/home_page.dart';

// Perfil
import 'features/profile/profile_page.dart';
import 'features/profile/edit_profile_page.dart';
import 'features/profile/settings_page.dart';

// Corrida
import 'features/run/vm/run_vm.dart';

// Histórico (MVVM)
import 'features/history/history_page.dart';
import 'features/history/vm/history_vm.dart';

// Resumo da corrida
import 'features/summary/run_summary_page.dart';

// 🕹️ Modo relógio tipo Garmin
import 'features/watch/watch_run_page.dart';

// 💪 Módulo de Treinos (MVVM)
import 'features/training/training_page.dart';
import 'features/training/create_training_page.dart';
import 'features/training/vm/training_vm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SafeRunApp());
}

class SafeRunApp extends StatefulWidget {
  const SafeRunApp({super.key});

  @override
  State<SafeRunApp> createState() => _SafeRunAppState();
}

class _SafeRunAppState extends State<SafeRunApp> {
  late FirebaseAnalytics analytics;
  late FirebaseAnalyticsObserver observer;

  @override
  void initState() {
    super.initState();
    analytics = FirebaseAnalytics.instance;
    observer = FirebaseAnalyticsObserver(analytics: analytics);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🌗 Tema global (claro/escuro)
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // 🏃 ViewModel da Corrida
        ChangeNotifierProvider(create: (_) => RunVM()),

        // 🧩 ViewModel do Histórico
        ChangeNotifierProvider(create: (_) => HistoryVM()),

        // 💪 ViewModel dos Treinos Personalizados
        ChangeNotifierProvider(create: (_) => TrainingVM()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'SafeRun',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // 🔹 Adiciona o Firebase Analytics Observer
            navigatorObservers: [observer],

            // ✅ Detecta automaticamente se é relógio ou celular
            home: LayoutBuilder(
              builder: (context, constraints) {
                final isWatch =
                    constraints.maxWidth < 400 && constraints.maxHeight < 400;

                if (isWatch) {
                  // 🎬 Transição suave para o modo relógio
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 900),
                    transitionBuilder: (child, animation) {
                      final fade = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      );
                      return FadeTransition(
                        opacity: fade,
                        child: ScaleTransition(scale: fade, child: child),
                      );
                    },
                    child: const WatchRunPage(),
                  );
                } else {
                  return const AuthGate(); // fluxo normal com login e home
                }
              },
            ),

            routes: {
              '/login': (context) => const LoginPage(),
              '/register': (context) => const RegisterPage(),
              '/reset-password': (context) => const ResetPasswordPage(),
              '/home': (context) => const HomePage(),
              '/profile': (context) => const ProfilePage(),
              '/edit-profile': (context) => const EditProfilePage(),
              '/settings': (context) => const SettingsPage(),
              '/history': (context) => const HistoryPage(),
              '/summary': (context) => RunSummaryPage(
                distance: 0,
                duration: Duration.zero,
                route: const [],
                onSave: () async {},
                onDiscard: () {},
              ),

              // 💪 Treinos personalizados (corrigido)
              '/training': (context) => const TrainingPage(),
              '/create-training': (context) => const CreateTrainingPage(),
              '/watch': (context) => const WatchRunPage(),
            },
          );
        },
      ),
    );
  }
}

/// 🔐 Controla a autenticação do usuário (celular)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
