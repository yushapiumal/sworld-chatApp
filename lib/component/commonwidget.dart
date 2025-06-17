import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

void triggerVibration() async {
  if (await Vibration.hasVibrator()) {
    Vibration.vibrate(duration: 200); // vibrates for 200ms
  }
}



