import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluetooth_thermal_printer_pro_method_channel.dart';

abstract class BluetoothThermalPrinterProPlatform extends PlatformInterface {
  /// Constructs a BluetoothThermalPrinterProPlatform.
  BluetoothThermalPrinterProPlatform() : super(token: _token);

  static final Object _token = Object();

  static BluetoothThermalPrinterProPlatform _instance = MethodChannelBluetoothThermalPrinterPro();

  /// The default instance of [BluetoothThermalPrinterProPlatform] to use.
  ///
  /// Defaults to [MethodChannelBluetoothThermalPrinterPro].
  static BluetoothThermalPrinterProPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BluetoothThermalPrinterProPlatform] when
  /// they register themselves.
  static set instance(BluetoothThermalPrinterProPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
