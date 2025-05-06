// lib/services/device_info_service.dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart'; // Для BuildContext и платформы
import '../../models/device_info.dart';

class DeviceInfoService {
  static Future<DeviceInfo> getDeviceInfo(BuildContext context) async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      final deviceInfo = DeviceInfo(
        os: 'Android',
        brief: 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt}), ${androidInfo.manufacturer} ${androidInfo.model}',
        deviceId: androidInfo.id,
        appVersion: '1.0.0', // Здесь можно использовать версию приложения
      );
      print('Собранная информация об устройстве: ${deviceInfo.toJson()}'); // Добавляем логирование
      return deviceInfo;
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      final deviceInfo = DeviceInfo(
        os: 'iOS',
        brief: 'iOS ${iosInfo.systemVersion}, ${iosInfo.model}',
        deviceId: iosInfo.identifierForVendor!,
        appVersion: '1.0.0', // Здесь можно использовать версию приложения
      );
      print('Собранная информация об устройстве: ${deviceInfo.toJson()}'); // Добавляем логирование
      return deviceInfo;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}