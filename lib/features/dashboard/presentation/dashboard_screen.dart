import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_provider.dart';
import '../../auth/domain/user_role.dart';
import '../../settings/data/gym_settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final role = user?.role;
    // Pakai nama gym asli dari modul Pengaturan kalau sudah diisi,
    // fallback ke label generik kalau belum/masih loading.
    final gymName = ref.watch(gymSettingsStreamProvider).valueOrNull?.gymName;

    final menuItems = <Widget>[
      if (role != null) ...[
        if (role.canAccess('members'))
          _MenuTile('Member', Icons.people_outline, () => context.push('/members')),
        if (role.canAccess('packages'))
          _MenuTile('Paket Membership', Icons.card_membership_outlined,
              () => context.push('/packages')),
        if (role.canAccess('checkin'))
          _MenuTile('Check-in', Icons.qr_code_scanner, () => context.push('/checkin')),
        if (role.canAccess('classes_view'))
          _MenuTile('Jadwal Kelas', Icons.calendar_month_outlined, () => context.push('/classes')),
        if (role.canAccess('payments'))
          _MenuTile('Pembayaran', Icons.payments_outlined, () => context.push('/payments')),
        if (role.canAccess('reports_operational'))
          _MenuTile('Laporan Operasional', Icons.insights_outlined,
              () => context.push('/reports/operational')),
        if (role.canAccess('staff_management'))
          _MenuTile(
              'Manajemen Staf', Icons.badge_outlined, () => context.push('/staff-management')),
        if (role.canAccess('reports_financial'))
          _MenuTile('Laporan Keuangan', Icons.account_balance_wallet_outlined,
              () => context.push('/reports/financial'), accentGold: true),
        if (role.canAccess('gym_settings'))
          _MenuTile('Pengaturan Gym', Icons.settings_outlined, () => context.push('/settings')),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(gymName?.isNotEmpty == true ? gymName! : 'Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ResponsiveCenter(
          maxWidth: 1100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang, ${user?.name ?? ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(role?.label ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 24),
              // Grid responsif: 1 kolom di HP, otomatis 2-3 kolom di layar
              // yang lebih lebar (tablet/web) — dihitung dari lebar area
              // yang benar-benar tersedia (LayoutBuilder), bukan lebar layar
              // penuh, supaya tetap akurat walau ResponsiveCenter membatasi
              // lebar maksimum di atas.
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = responsiveColumns(context, mobile: 1, tablet: 2, desktop: 3);
                  const spacing = 12.0;
                  final tileWidth = columns == 1
                      ? constraints.maxWidth
                      : (constraints.maxWidth - spacing * (columns - 1)) / columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final tile in menuItems) SizedBox(width: tileWidth, child: tile),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool accentGold;

  const _MenuTile(this.title, this.icon, this.onTap, {this.accentGold = false});

  @override
  Widget build(BuildContext context) {
    final accent = accentGold ? AppColors.gold : AppColors.emeraldBright;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
