import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth_thermal_printer_pro/bluetooth_thermal_printer_pro.dart';

void main() {
  const MethodChannel channel = MethodChannel('bluetooth_thermal_printer_pro');

  // Ensure test binding initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock the platform channel responses
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getPlatformVersion') {
        return 'Android 42';
      }
      // Add other mocked methods if needed
      return null;
    });
  });

  tearDown(() {
    // Remove the mock after each test
    channel.setMockMethodCallHandler(null);
  });

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    // Call the static method on the class
    final String? version =
        await BluetoothThermalPrinterPro.getPlatformVersion();

    // Assertions
    expect(version, isNotNull);
    expect(version, equals('Android 42'));
  });
}
