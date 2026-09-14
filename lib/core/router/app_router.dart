import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_provider.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/members/domain/member.dart';
import '../../features/members/presentation/member_form_screen.dart';
import '../../features/members/presentation/members_screen.dart';
import '../../features/packages/domain/membership_package.dart';
import '../../features/packages/presentation/package_form_screen.dart';
import '../../features/packages/presentation/packages_screen.dart';
import '../../features/checkin/presentation/checkin_screen.dart';
import '../../features/classes/domain/class_schedule.dart';
import '../../features/classes/presentation/class_detail_screen.dart';
import '../../features/classes/presentation/class_form_screen.dart';
import '../../features/classes/presentation/classes_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/payments/presentation/payment_form_screen.dart';

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
      GoRoute(path: '/members', builder: (context, state) => const MembersScreen()),
      GoRoute(
        path: '/members/new',
        builder: (context, state) => const MemberFormScreen(),
      ),
      GoRoute(
        path: '/members/:id',
        builder: (context, state) => MemberFormScreen(
          existingMember: state.extra as Member?,
        ),
      ),
      GoRoute(path: '/packages', builder: (context, state) => const PackagesScreen()),
      GoRoute(
        path: '/packages/new',
        builder: (context, state) => const PackageFormScreen(),
      ),
      GoRoute(
        path: '/packages/:id',
        builder: (context, state) => PackageFormScreen(
          existingPackage: state.extra as MembershipPackage?,
        ),
      ),
      GoRoute(path: '/checkin', builder: (context, state) => const CheckinScreen()),
      GoRoute(path: '/classes', builder: (context, state) => const ClassesScreen()),
      GoRoute(
        path: '/classes/:id',
        builder: (context, state) => ClassDetailScreen(
          schedule: state.extra as ClassSchedule,
        ),
      ),
      GoRoute(
        path: '/class-management/new',
        builder: (context, state) => const ClassFormScreen(),
      ),
      GoRoute(
        path: '/class-management/:id',
        builder: (context, state) => ClassFormScreen(
          existingClass: state.extra as ClassSchedule?,
        ),
      ),
      GoRoute(path: '/payments', builder: (context, state) => const PaymentsScreen()),
      GoRoute(path: '/payments/new', builder: (context, state) => const PaymentFormScreen()),
      // Tambahkan route modul lain di sini, contoh:
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
    '/classes': 'classes_view',
    '/class-management': 'classes_schedule',
    '/reports/operational': 'reports_operational',
    '/checkin': 'checkin',
  };
  // Prefix-match supaya sub-route seperti '/packages/new' atau '/members/abc123'
  // ikut terproteksi oleh featureKey induknya, bukan cuma path persis.
  for (final entry in map.entries) {
    if (path == entry.key || path.startsWith('${entry.key}/')) {
      return entry.value;
    }
  }
  return null;
}

/// Supaya GoRouter re-evaluate redirect setiap kali auth state berubah.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this.ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}
