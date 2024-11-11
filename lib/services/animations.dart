// animations.dart
import 'package:crudtutorial/constants.dart';
import 'package:flutter/material.dart';


class SharedAnimations {
  static Animation<double> fadeIn(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: AnimationConstants.defaultCurve,
        reverseCurve: AnimationConstants.defaultCurve,
      ),
    );
  }

  static Animation<Offset> slideIn(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: AnimationConstants.defaultCurve,
      ),
    );
  }
}