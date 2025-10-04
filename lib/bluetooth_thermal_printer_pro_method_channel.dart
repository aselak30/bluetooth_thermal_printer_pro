import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bluetooth_thermal_printer_pro_platform_interface.dart';

/// An implementation of [BluetoothThermalPrinterProPlatform] that uses method channels.
class MethodChannelBluetoothThermalPrinterPro extends BluetoothThermalPrinterProPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bluetooth_thermal_printer_pro');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
