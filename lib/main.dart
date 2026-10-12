import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'services/admin_state_service.dart';
import 'theme/admin_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for Takse Call Super Admin Web
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully for takse-call-admin-web');
    AdminStateService.instance.initFirebase();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const TakseCallAdminApp());
}

class TakseCallAdminApp extends StatelessWidget {
  const TakseCallAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AdminStateService.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return MaterialApp(
          title: 'Takse Call • Super Admin Platform',
          debugShowCheckedModeBanner: false,
          theme: AdminTheme.lightTheme,
          darkTheme: AdminTheme.darkTheme,
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AdminRootRouter(),
        );
      },
    );
  }
}

class AdminRootRouter extends StatefulWidget {
  const AdminRootRouter({super.key});

  @override
  State<AdminRootRouter> createState() => _AdminRootRouterState();
}

class _AdminRootRouterState extends State<AdminRootRouter> {
  bool _hasSplashed = false;

  @override
  Widget build(BuildContext context) {
    if (!_hasSplashed) {
      return AdminSplashScreen(
        onFinish: () {
          if (mounted) setState(() => _hasSplashed = true);
        },
      );
    }

    final state = AdminStateService.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        if (!state.isAuthenticated) {
          return AdminLoginScreen(
            onLoginSuccess: () {
              // Navigated reactively by ListenableBuilder
            },
          );
        }
        return const MainShell();
      },
    );
  }
}
