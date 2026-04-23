import 'package:flutter/material.dart';

/// Utility class untuk responsive sizing.
/// Semua nilai dihitung relatif terhadar ukuran layar aktual device.
/// Base design reference: 390w × 844h (iPhone 14 / mid-range Android)
class AppSize {
  static late MediaQueryData _mq;

  static double _screenW = 390;
  static double _screenH = 844;

  /// Wajib dipanggil sekali di awal build() setiap halaman,
  /// atau bisa di MaterialApp builder.
  static void init(BuildContext context) {
    _mq = MediaQuery.of(context);
    _screenW = _mq.size.width;
    _screenH = _mq.size.height;
  }

  /// Lebar layar penuh
  static double get screenW => _screenW;

  /// Tinggi layar penuh
  static double get screenH => _screenH;

  /// Safe area top (status bar)
  static double get statusBar => _mq.padding.top;

  /// Safe area bottom (home indicator / navbar gesture)
  static double get bottomInset => _mq.padding.bottom;

  /// Responsive width — proporsional terhadap lebar layar
  /// Contoh: AppSize.w(20) → 20px di layar 390px, lebih besar di layar lebar
  static double w(double val) => (_screenW / 390) * val;

  /// Responsive height — proporsional terhadap tinggi layar
  /// Contoh: AppSize.h(30) → 30px di layar 844px, lebih besar di layar tinggi
  static double h(double val) => (_screenH / 844) * val;

  /// Responsive font size — menggunakan lebar sebagai acuan
  static double sp(double val) => (_screenW / 390) * val;

  /// Responsive radius
  static double r(double val) => (_screenW / 390) * val;

  /// True jika layar < 360dp (HP kecil seperti Samsung Galaxy A03s)
  static bool get isSmall => _screenW < 360;

  /// True jika layar >= 600dp (tablet)
  static bool get isTablet => _screenW >= 600;
}
