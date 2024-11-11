// constants.dart
import 'package:flutter/material.dart';

class AnimationConstants {
  static const Duration quickDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bouncyCurve = Curves.elasticOut;
}