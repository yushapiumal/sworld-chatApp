import 'package:flutter/material.dart';
import 'package:sworld_flutter/component/Text/textColors.dart';

class AppTextStyles {
  static const String fontFamily = 'Roboto'; 

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
    fontFamily: fontFamily,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    fontFamily: fontFamily,
  );
  static const TextStyle buttoncancelText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    fontFamily: fontFamily,
  );

  static const TextStyle errorText = TextStyle(
    fontSize: 14,
    color: AppColors.error,
    fontFamily: fontFamily,
  );
  static const TextStyle successText = TextStyle(
    fontSize: 14,
    color: Color.fromARGB(255, 30, 236, 47),
    fontFamily: fontFamily,
  );
}
