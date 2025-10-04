import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth_thermal_printer_pro/bluetooth_thermal_printer_pro.dart';
import 'package:bluetooth_thermal_printer_pro/bluetooth_thermal_printer_pro_platform_interface.dart';
import 'package:bluetooth_thermal_printer_pro/bluetooth_thermal_printer_pro_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBluetoothThermalPrinterProPlatform
    with MockPlatformInterfaceMixin
    implements BluetoothThermalPrinterProPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BluetoothThermalPrinterProPlatform initialPlatform =
      BluetoothThermalPrinterProPlatform.instance;

  test('$MethodChannelBluetoothThermalPrinterPro is the default instance', () {
    expect(initialPlatform,
        isInstanceOf<MethodChannelBluetoothThermalPrinterPro>());
  });

  test('getPlatformVersion', () async {
    // BluetoothThermalPrinterPro bluetoothThermalPrinterProPlugin =
    //     BluetoothThermalPrinterPro();
    MockBluetoothThermalPrinterProPlatform fakePlatform =
        MockBluetoothThermalPrinterProPlatform();
    BluetoothThermalPrinterProPlatform.instance = fakePlatform;

    expect(await BluetoothThermalPrinterPro.getPlatformVersion(), '42');
  });
}
