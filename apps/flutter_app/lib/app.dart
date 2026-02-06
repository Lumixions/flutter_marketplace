import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/buyer/buyer_shell.dart';
import 'features/seller/seller_shell.dart';
import 'features/seller/seller_product_create_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/seller',
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'];
            return SellerShell(initialTab: tab);
          },
        ),
        GoRoute(
          path: '/seller/products/new',
          builder: (context, state) => const SellerProductCreateScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const BuyerShell(),
        ),
      ],
      redirect: (context, state) {
        final auth = ref.read(authStateProvider);
        final loggedIn = auth.valueOrNull != null;
        final goingToLogin = state.matchedLocation == '/login';

        if (!loggedIn && !goingToLogin) return '/login';
        if (loggedIn && goingToLogin) return '/';
        return null;
      },
      refreshListenable: GoRouterRefreshStream(
        ref.read(authChangesProvider.stream),
      ),
    );

    return MaterialApp.router(
      title: 'Marketplace V2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

/// Minimal adapter to refresh router on stream events.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

