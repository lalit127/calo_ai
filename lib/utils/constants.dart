
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Constants {
  //static const String userAccessTokenKey = 'USER_ACCESS_TOKEN';
  static const String PROFILE = 'Profile';
  static const String SPLASH = 'Splash';
  ///Api
  // static const String baseUrl = 'http://192.168.1.6:3200/';
  static const String baseUrl = 'https://calo-backend-production.up.railway.app/';

//'http://192.168.1.35:3000/';
// static const String baseUrl = 'http://192.168.1.12:3200/';

}

void appPrint(object) {
  if (kDebugMode) {
    log('$object');
  }
}
