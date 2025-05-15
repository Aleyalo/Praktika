import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // Для BuildContext и платформы
import '../../models/device_info.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Импортируем package_info_plus для получения версии приложения

class DeviceInfoService {
  static Future<DeviceInfo> getDeviceInfo(BuildContext? context) async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String os;
    String brief;
    String deviceId;
    String appVersion;

    if (context != null) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        os = 'Android';
        brief = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
        deviceId = androidInfo.id;
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        os = 'iOS';
        brief = 'iOS ${iosInfo.systemVersion}';
        deviceId = iosInfo.identifierForVendor!;
      } else {
        throw UnsupportedError('Unsupported platform');
      }
    } else {
      // Если контекста нет, используем стандартные значения или получаем deviceId из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      deviceId = prefs.getString('deviceId') ?? '';
      if (deviceId.isEmpty) {
        throw Exception('deviceId не найден');
      }
      os = 'Android'; // Предполагаем, что устройство Android, если контекст отсутствует
      brief = 'Android 13 (SDK 33)'; // Используем стандартные значения
    }

    // Получаем версию приложения
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;

    final deviceInfo = DeviceInfo(
      os: os,
      brief: brief,
      deviceId: deviceId,
      appVersion: appVersion,
    );

    print('Собранная информация об устройстве: ${deviceInfo.toJson()}'); // Добавляем логирование
    return deviceInfo;
  }
}