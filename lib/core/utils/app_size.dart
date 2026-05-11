import 'package:flutter/material.dart';

class AppSize {
  static late MediaQueryData _mq;

  static double _screenW = 390;
  static double _screenH = 844;

  static void init(BuildContext context) {
    _mq = MediaQuery.of(context);
    _screenW = _mq.size.width;
    _screenH = _mq.size.height;
  }

  static double get screenW => _screenW;

  static double get screenH => _screenH;

  static double get statusBar => _mq.padding.top;

  static double get bottomInset => _mq.padding.bottom;

  static double w(double val) => (_screenW / 390) * val;

  static double h(double val) => (_screenH / 844) * val;

  static double sp(double val) => (_screenW / 390) * val;

  static double r(double val) => (_screenW / 390) * val;

  static bool get isSmall => _screenW < 360;

  static bool get isTablet => _screenW >= 600;
}
