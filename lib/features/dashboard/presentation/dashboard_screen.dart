import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_provider.dart';
import '../../auth/domain/user_role.dart';
import '../../settings/data/gym_settings_provider.dart';
import '../../checkin/data/checkin_provider.dart';
import '../../reports/data/reports_provider.dart';
import '../../classes/data/class_schedule_provider.dart';
import '../../classes/domain/class_schedule.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive.dart';
import '../../../shared/format_rupiah.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final role = user?.role;
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
              if (role != null) _HeroBanner(user: user!, role: role, gymName: gymName),
              const SizedBox(height: 20),
              if (role != null) _StatCardsSection(role: role),
              const SizedBox(height: 20),
              if (role != null) _ActivityPanelsSection(role: role),
              const SizedBox(height: 28),
              Text('Menu', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
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

/// Banner sambutan: badge role aktif, nama user, nama gym, dan tombol aksi
/// cepat (cuma yang role-nya berhak).
class _HeroBanner extends StatelessWidget {
  final AppUser user;
  final UserRole role;
  final String? gymName;

  const _HeroBanner({required this.user, required this.role, required this.gymName});

  @override
  Widget build(BuildContext context) {
    final quickActions = <Widget>[
      if (role.canAccess('checkin'))
        _QuickActionButton(
          label: 'Check-in Member',
          icon: Icons.qr_code_scanner,
          filled: true,
          onTap: () => context.push('/checkin'),
        ),
      if (role.canAccess('payments'))
        _QuickActionButton(
          label: 'Catat Bayar',
          icon: Icons.payments_outlined,
          onTap: () => context.push('/payments/new'),
        ),
      if (role.canAccess('members'))
        _QuickActionButton(
          label: 'Member Baru',
          icon: Icons.person_add_alt,
          onTap: () => context.push('/members/new'),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.emeraldBright.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.emeraldBright.withOpacity(0.4)),
            ),
            child: Text(
              'Mode Akses: ${role.label.toUpperCase()}',
              style: const TextStyle(
                  color: AppColors.emeraldBright, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Text('Selamat Datang, ${user.name}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            '${gymName?.isNotEmpty == true ? gymName : 'Gym Anda'} — siap melayani kehadiran member, sesi kelas, dan transaksi membership hari ini.',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          if (quickActions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(spacing: 10, runSpacing: 10, children: quickActions),
          ],
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label));
    }
    return OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label));
  }
}

/// 4 kartu statistik: check-in hari ini, member aktif, sesi kelas hari ini,
/// pendapatan bulan ini — masing-masing cuma tampil kalau role-nya berhak.
class _StatCardsSection extends ConsumerWidget {
  final UserRole role;
  const _StatCardsSection({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = <Widget>[];

    if (role.canAccess('checkin')) {
      final checkinsAsync = ref.watch(todayCheckinsProvider);
      cards.add(_StatCard(
        label: 'Check-in Hari Ini',
        icon: Icons.qr_code_scanner,
        value: checkinsAsync.whenOrNull(data: (list) => '${list.length}') ?? '—',
        suffix: 'kunjungan member',
        linkLabel: 'Buka meja check-in',
        onTap: () => context.push('/checkin'),
      ));
    }

    if (role.canAccess('members')) {
      final statusAsync = ref.watch(memberStatusCountsProvider);
      int countFor(List list, String s) {
        for (final e in list) {
          if (e.status == s) return e.count as int;
        }
        return 0;
      }

      cards.add(_StatCard(
        label: 'Member Aktif',
        icon: Icons.people_outline,
        value: statusAsync.whenOrNull(data: (list) => '${countFor(list, 'active')}') ?? '—',
        suffix: statusAsync.whenOrNull(data: (list) {
              final total = list.fold<int>(0, (sum, s) => sum + (s.count as int));
              return 'dari $total member';
            }) ??
            '',
        linkLabel: 'Lihat data member',
        onTap: () => context.push('/members'),
        footnote: statusAsync.whenOrNull(data: (list) {
          return '${countFor(list, 'expiring_soon')} Segera Habis  ·  ${countFor(list, 'expired')} Kedaluwarsa';
        }),
      ));
    }

    if (role.canAccess('classes_view')) {
      final classesAsync = ref.watch(classSchedulesStreamProvider);
      final today = DayOfWeekX.fromIsoWeekday(DateTime.now().weekday);
      cards.add(_StatCard(
        label: 'Sesi Kelas Hari Ini',
        icon: Icons.calendar_month_outlined,
        value: classesAsync.whenOrNull(
              data: (list) => '${list.where((c) => c.dayOfWeek == today).length}',
            ) ??
            '—',
        suffix: 'jadwal rutin',
        linkLabel: 'Lihat jadwal & booking',
        onTap: () => context.push('/classes'),
      ));
    }

    if (role.canAccess('reports_financial')) {
      final revenueAsync = ref.watch(revenueByMonthProvider);
      cards.add(_StatCard(
        label: 'Pendapatan Bulan Ini',
        icon: Icons.trending_up,
        value: revenueAsync.whenOrNull(
              data: (list) => list.isEmpty ? formatRupiah(0) : formatRupiah(list.last.total),
            ) ??
            '—',
        suffix: '',
        linkLabel: 'Lihat riwayat transaksi',
        onTap: () => context.push('/reports/financial'),
        accentGold: true,
      ));
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = responsiveColumns(context, mobile: 2, tablet: 2, desktop: 4);
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final c in cards) SizedBox(width: cardWidth, child: c)],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String suffix;
  final String linkLabel;
  final VoidCallback onTap;
  final String? footnote;
  final bool accentGold;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.suffix,
    required this.linkLabel,
    required this.onTap,
    this.footnote,
    this.accentGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentGold ? AppColors.gold : AppColors.emeraldBright;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 0.4),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: accent.withOpacity(0.14), shape: BoxShape.circle),
                child: Icon(icon, size: 15, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (suffix.isNotEmpty) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(suffix, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ),
              ],
            ],
          ),
          if (footnote != null) ...[
            const SizedBox(height: 4),
            Text(footnote!, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(linkLabel,
                    style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
                Icon(Icons.arrow_forward, size: 13, color: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2 panel: Aktivitas Check-in Terbaru & Kelas Hari Ini — berdampingan di
/// layar lebar, bertumpuk di HP.
class _ActivityPanelsSection extends StatelessWidget {
  final UserRole role;
  const _ActivityPanelsSection({required this.role});

  @override
  Widget build(BuildContext context) {
    final panels = <Widget>[
      if (role.canAccess('checkin')) const _RecentCheckinsPanel(),
      if (role.canAccess('classes_view')) const _TodayClassesPanel(),
    ];

    if (panels.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < Breakpoints.mobile;
        if (isNarrow || panels.length == 1) {
          return Column(
            children: [
              for (int i = 0; i < panels.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                panels[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < panels.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: panels[i]),
            ],
          ],
        );
      },
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final String? linkLabel;
  final VoidCallback? onLinkTap;
  final Widget child;

  const _PanelCard({required this.title, this.linkLabel, this.onLinkTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (linkLabel != null)
                InkWell(
                  onTap: onLinkTap,
                  child: Text(linkLabel!,
                      style: const TextStyle(
                          color: AppColors.emeraldBright, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RecentCheckinsPanel extends ConsumerWidget {
  const _RecentCheckinsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(todayCheckinsProvider);

    return _PanelCard(
      title: 'Aktivitas Check-in Terbaru',
      linkLabel: 'Meja Check-in →',
      onLinkTap: () => context.push('/checkin'),
      child: checkinsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Text('Gagal memuat: $err', style: const TextStyle(fontSize: 12)),
        data: (list) {
          if (list.isEmpty) {
            return const Text('Belum ada check-in hari ini.',
                style: TextStyle(color: AppColors.muted, fontSize: 13));
          }
          final recent = list.take(5).toList();
          return Column(
            children: [
              for (final c in recent)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.statusActive, size: 16),
                      const SizedBox(width: 10),
                      Expanded(child: Text(c.memberName, style: const TextStyle(fontSize: 13))),
                      Text(_formatTime(c.checkedInAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _TodayClassesPanel extends ConsumerWidget {
  const _TodayClassesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classSchedulesStreamProvider);
    final today = DayOfWeekX.fromIsoWeekday(DateTime.now().weekday);

    return _PanelCard(
      title: 'Kelas Hari Ini',
      linkLabel: 'Semua Jadwal →',
      onLinkTap: () => context.push('/classes'),
      child: classesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Text('Gagal memuat: $err', style: const TextStyle(fontSize: 12)),
        data: (list) {
          final todayClasses = list.where((c) => c.dayOfWeek == today).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          if (todayClasses.isEmpty) {
            return Text('Tidak ada jadwal kelas rutin untuk hari ini (${today.label}).',
                style: const TextStyle(color: AppColors.muted, fontSize: 13));
          }
          return Column(
            children: [
              for (final c in todayClasses)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.emeraldBright,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('${c.startTime} · ${c.trainerName}',
                                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
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
