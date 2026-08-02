import 'package:go_router/go_router.dart';

import '../core/constants/route_constants.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter _router = GoRouter(
    initialLocation: RouteConstants.splash,
    routes: [
      GoRoute(
        path: RouteConstants.splash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(path: RouteConstants.login, builder: (_, _) => const LoginPage()),
    ],
  );

  static GoRouter router() => _router;

  static void goToLogin() {
    _router.go(RouteConstants.login);
  }
}
