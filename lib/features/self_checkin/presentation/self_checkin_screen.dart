import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/self_checkin_provider.dart';
import '../domain/self_checkin_result.dart';
import '../../members/domain/member.dart';
import '../../settings/data/gym_settings_provider.dart';
import '../../../core/theme/app_theme.dart';

class SelfCheckinScreen extends ConsumerStatefulWidget {
  const SelfCheckinScreen({super.key});

  @override
  ConsumerState<SelfCheckinScreen> createState() => _SelfCheckinScreenState();
}

class _SelfCheckinScreenState extends ConsumerState<SelfCheckinScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selfCheckinControllerProvider);
    final gymName = ref.watch(gymSettingsStreamProvider).valueOrNull?.gymName;
    final isLoading = state.isLoading;

    ref.listen(selfCheckinControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (result) {
          if (result != null) {
            _showResultDialog(context, result);
          }
        },
        error: (err, _) {
          final message = err is MemberNotFoundException ? err.message : 'Terjadi kesalahan: $err';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.statusDanger),
          );
        },
      );
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 2, color: AppColors.gold),
                  const SizedBox(height: 20),
                  Text(
                    gymName?.isNotEmpty == true ? gymName! : 'CHECK-IN MEMBER',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Masukkan nomor HP yang terdaftar untuk check-in',
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _phoneController,
                    focusNode: _focusNode,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 1),
                    decoration: const InputDecoration(
                      hintText: '08xxxxxxxxxx',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    obscureText: true,
                    maxLength: 4,
                    style: const TextStyle(fontSize: 22, letterSpacing: 6),
                    decoration: const InputDecoration(
                      hintText: 'PIN (kalau punya)',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                            )
                          : const Icon(Icons.qr_code_scanner),
                      label: Text(isLoading ? 'Memproses...' : 'Check-in',
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    child: const Text('Kembali ke halaman login staf'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    ref.read(selfCheckinControllerProvider.notifier).checkIn(phone, pin: _pinController.text.trim());
  }

  void _showResultDialog(BuildContext context, SelfCheckinResult result) {
    final (statusLabel, statusColor) = switch (result.status) {
      MembershipStatus.active => ('Aktif', AppColors.statusActive),
      MembershipStatus.expiringSoon => ('Segera Habis', AppColors.statusWarning),
      MembershipStatus.expired => ('Kedaluwarsa', AppColors.statusDanger),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: AppColors.statusActive, size: 28),
            SizedBox(width: 10),
            Text('Check-in Berhasil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultRow('Nama Member', result.memberName),
            _ResultRow('Paket', result.packageName),
            _ResultRow('Berlaku s/d', _formatDate(result.membershipEndDate)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.status == MembershipStatus.expiringSoon
                    ? 'Membership Anda $statusLabel — segera perpanjang di kasir.'
                    : result.status == MembershipStatus.expired
                        ? 'Membership Anda $statusLabel — silakan perpanjang di kasir.'
                        : 'Status membership: $statusLabel',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _phoneController.clear();
              _pinController.clear();
              ref.read(selfCheckinControllerProvider.notifier).reset();
              _focusNode.requestFocus();
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
