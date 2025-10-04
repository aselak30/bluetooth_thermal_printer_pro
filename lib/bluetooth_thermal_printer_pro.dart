import 'dart:async';
import 'package:flutter/services.dart';

class BluetoothThermalPrinterPro {
  static const MethodChannel _channel =
      MethodChannel('bluetooth_thermal_printer_pro');

  static Future<String?> getPlatformVersion() async {
    return await _channel.invokeMethod<String>('getPlatformVersion');
  }

  static Future<String> bluetoothStatus() async {
    return await _channel.invokeMethod<String>('BluetoothStatus') ?? 'false';
  }

  static Future<String> connectionStatus() async {
    return await _channel.invokeMethod<String>('connectionStatus') ?? 'false';
  }

  static Future<String> connectPrinter(String mac) async {
    return await _channel.invokeMethod<String>('connectPrinter', mac) ??
        'false';
  }

  static Future<String> writeBytes(List<int> bytes) async {
    return await _channel.invokeMethod<String>('writeBytes', bytes) ?? 'false';
  }

  static Future<String> printText(String textWithSizePrefix) async {
    return await _channel.invokeMethod<String>(
            'printText', textWithSizePrefix) ??
        'false';
  }

  static Future<String?> printImage(Uint8List imageBytes) async {
    final result = await _channel.invokeMethod(
      'printImage',
      {'bytes': imageBytes},
    );
    return result;
  }

  static Future<List<String>> getLinkedDevices() async {
    final List<dynamic>? result =
        await _channel.invokeMethod<List<dynamic>>('bluetothLinked');
    if (result == null) return <String>[];
    return result.cast<String>();
  }
}
