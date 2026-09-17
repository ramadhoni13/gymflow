import 'package:flutter/material.dart';

/// Breakpoint sederhana. Aplikasi ini menyasar Web (bisa dibuka di layar
/// lebar) dan Android (sempit) — helper ini dipakai supaya layout yang
/// sama tetap enak dilihat di kedua kondisi, bukan cuma "menyusut".
class Breakpoints {
  Breakpoints._();
  static const mobile = 600.0;
  static const tablet = 1024.0;
}

bool isMobileWidth(BuildContext context) =>
    MediaQuery.of(context).size.width < Breakpoints.mobile;

bool isTabletWidth(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.mobile &&
    MediaQuery.of(context).size.width < Breakpoints.tablet;

bool isDesktopWidth(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.tablet;

/// Jumlah kolom grid yang disarankan berdasarkan lebar layar saat ini.
int responsiveColumns(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
  final width = MediaQuery.of(context).size.width;
  if (width >= Breakpoints.tablet) return desktop;
  if (width >= Breakpoints.mobile) return tablet;
  return mobile;
}

/// Bungkus konten supaya lebarnya dibatasi & di-tengah-kan di layar lebar
/// (web/desktop/tablet landscape), tapi tetap full-width apa adanya di HP.
/// Dipakai untuk halaman list/form supaya tidak melebar penuh sampai tepi
/// layar di browser desktop (yang bikin baris jadi sangat panjang & buruk
/// dibaca), tanpa mengubah apa pun di layar sempit.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 900});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
