import 'dart:io';
import 'package:cal_ai/theme/app_colors.dart';
import 'package:cal_ai/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatusBarColorController extends GetxController {
  Rx<Color> statusBarColor = AppColors.backgroundLight.obs;

  void changeStatusBarColor(String pageTitle) {
    if (Platform.isAndroid) {
      if (pageTitle == Constants.PROFILE) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: AppColors.backgroundLight,
          statusBarIconBrightness: Brightness.dark,
        ));
      } else if (pageTitle == Constants.SPLASH) {
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: AppColors.secondaryColor,
          statusBarIconBrightness: Brightness.light,
        ));
      } else {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: AppColors.whiteOff,
          statusBarIconBrightness: Brightness.dark,
        ));
      }
    }
    update();
  }

  onBackPress(String pageTitle) {
    return () {
      changeStatusBarColor(pageTitle);
      Get.back();
    };
  }

  ThemeMode themeMode = ThemeMode.dark;
  bool isThemeDark = false;
  isDark(bool isDark) async {
    try {
      isThemeDark = isDark;
      themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      SharedPreferences.getInstance().then((pref) {
        pref.setBool('darkMode', isDark);
      });
    } catch (onError) {
      //Constants.getErrorResponse(onError);
    }
  }
}
