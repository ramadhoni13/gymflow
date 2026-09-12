import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_provider.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

/// Setiap route yang butuh proteksi didaftarkan dengan featureKey-nya,
/// dicocokkan ke UserRoleX.canAccess().
class AppRoute {
  final String path;
  final String? featureKey; // null = boleh diakses semua role yang login
  const AppRoute(this.path, {this.featureKey});
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }
      if (isLoggingIn) {
        return '/dashboard';
      }

      final role = authState.valueOrNull?.role;
      final featureKey = _featureKeyFor(state.matchedLocation);
      if (role != null && featureKey != null && !role.canAccess(featureKey)) {
        return '/unauthorized';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Kamu tidak punya akses ke halaman ini.')),
        ),
      ),
      // Tambahkan route modul lain di sini, contoh:
      // GoRoute(path: '/members', builder: (context, state) => const MembersScreen()),
      // GoRoute(path: '/staff-management', builder: (context, state) => const StaffManagementScreen()),
    ],
  );
});

String? _featureKeyFor(String path) {
  const map = {
    '/staff-management': 'staff_management',
    '/reports/financial': 'reports_financial',
    '/settings': 'gym_settings',
    '/members': 'members',
    '/packages': 'packages',
    '/payments': 'payments',
    '/classes-schedule': 'classes_schedule',
    '/reports/operational': 'reports_operational',
    '/checkin': 'checkin',
  };
  return map[path];
}

/// Supaya GoRouter re-evaluate redirect setiap kali auth state berubah.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this.ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}
