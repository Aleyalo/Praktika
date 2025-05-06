class DeviceInfo {
  final String os;
  final String brief;
  final String deviceId;
  final String appVersion;

  DeviceInfo({
    required this.os,
    required this.brief,
    required this.deviceId,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'os': os,
      'brief': brief,
      'deviceId': deviceId,
      'appVersion': appVersion,
    };
  }
}