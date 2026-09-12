import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_provider.dart';
import '../../auth/domain/user_role.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final role = user?.role;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard — ${role?.label ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Halo, ${user?.name ?? ''} 👋', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (role != null) ...[
            if (role.canAccess('members')) _MenuTile('Member', Icons.people, () {}),
            if (role.canAccess('packages')) _MenuTile('Paket Membership', Icons.card_membership, () {}),
            if (role.canAccess('checkin')) _MenuTile('Check-in', Icons.qr_code_scanner, () {}),
            if (role.canAccess('classes_view')) _MenuTile('Jadwal Kelas', Icons.calendar_month, () {}),
            if (role.canAccess('payments')) _MenuTile('Pembayaran', Icons.payments, () {}),
            if (role.canAccess('reports_operational')) _MenuTile('Laporan Operasional', Icons.bar_chart, () {}),
            if (role.canAccess('staff_management')) _MenuTile('Manajemen Staf', Icons.badge, () {}),
            if (role.canAccess('reports_financial')) _MenuTile('Laporan Keuangan', Icons.account_balance_wallet, () {}),
            if (role.canAccess('gym_settings')) _MenuTile('Pengaturan Gym', Icons.settings, () {}),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile(this.title, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
