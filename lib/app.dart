import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/splash/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'services/firebase_auth_service.dart';
import 'services/pos_store.dart';
import 'widgets/app_shell.dart';

class RetailXApp extends StatelessWidget {
  const RetailXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => FirebaseAuthService()),
        ChangeNotifierProvider(create: (_) => PosStore()),
        ChangeNotifierProxyProvider2<PosStore, FirebaseAuthService, AuthProvider>(
          create: (ctx) => AuthProvider(
            ctx.read<PosStore>(),
            ctx.read<FirebaseAuthService>(),
          ),
          update: (_, store, authService, auth) =>
              auth ?? AuthProvider(store, authService),
        ),
      ],
      child: MaterialApp(
        title: 'RetailX POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _RootGate(),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.splashComplete) {
      return const SplashScreen();
    }

    if (!auth.authReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.isLoggedIn) {
      final store = context.watch<PosStore>();
      if (!store.synced) {
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Syncing store data…'),
              ],
            ),
          ),
        );
      }
      return const AppShell();
    }

    if (auth.loginRole == null) {
      return const RoleSelectionScreen();
    }

    return const LoginScreen();
  }
}
