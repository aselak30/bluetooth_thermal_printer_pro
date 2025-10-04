import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:bluetooth_thermal_printer_pro/bluetooth_thermal_printer_pro.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(
    const MaterialApp(
      home: MyApp(), // MaterialApp is at the top
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String status = '';
  List<String> devices = [];
  String? selectedDevice;

  @override
  void initState() {
    super.initState();
    // Schedule after first frame to safely use ScaffoldMessenger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatus();
    });
  }

  Future<void> _pickAndPrintImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) {
      _showSnackBar("No image selected");
      return;
    }

    final Uint8List bytes = await file.readAsBytes();

    if (await BluetoothThermalPrinterPro.connectionStatus() != 'true') {
      _showSnackBar("Printer not connected");
      return;
    }

    final result = await BluetoothThermalPrinterPro.printImage(bytes);
    _showSnackBar(
      result == 'true' ? "Image printed successfully" : "Image print failed",
    );
  }

  Future<void> _loadStatus() async {
    // Request necessary permissions first
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
      Permission.location,
    ].request();

    bool granted = statuses.values.every((s) => s.isGranted);
    if (!granted) {
      _showSnackBar('Bluetooth & Location permissions are required');
      setState(() {
        status = 'Permission denied';
      });
      return;
    }

    try {
      final s = await BluetoothThermalPrinterPro.bluetoothStatus();
      setState(() {
        // Ensure we show "Enabled" or "Disabled"
        status = (s == 'true') ? 'Enabled' : 'Disabled';
      });
    } catch (e) {
      setState(() {
        status = 'Error checking Bluetooth';
      });
      _showSnackBar('Error: $e');
    }

    // Load paired devices if Bluetooth is enabled
    if (status == 'Enabled') {
      try {
        final list = await BluetoothThermalPrinterPro.getLinkedDevices();
        setState(() {
          devices = list;
          if (list.isNotEmpty) selectedDevice = list[0];
        });
      } catch (e) {
        _showSnackBar('Failed to load devices: $e');
      }
    }
  }

  Future<void> _connectPrinter() async {
    if (selectedDevice == null) {
      _showSnackBar('Select a device first');
      return;
    }

    final mac = selectedDevice!.split('#').last;
    final connected = await BluetoothThermalPrinterPro.connectPrinter(mac);
    setState(() {
      status = connected == 'true' ? 'Connected' : 'Disconnected';
    });
    _showSnackBar('Printer connection: $status');
  }

  Future<void> _printSample() async {
    if (await BluetoothThermalPrinterPro.connectionStatus() != 'true') {
      _showSnackBar('Printer not connected');
      return;
    }

    const sampleText = '''
=== Sample Receipt ===
Item 1       10.00
Item 2       15.50
---------------------
Total        25.50
=====================
''';

    final result = await BluetoothThermalPrinterPro.printText(sampleText);
    _showSnackBar(result == 'true' ? 'Printed successfully' : 'Print failed');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BT Printer Pro Example')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bluetooth Status: $status'),
            const SizedBox(height: 12),
            const Text('Paired Devices:'),
            DropdownButton<String>(
              value: selectedDevice,
              items: devices
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDevice = value;
                });
              },
            ),
            const SizedBox(height: 12),

            // Row(
            //   children: [
            //     ElevatedButton(
            //       onPressed: _connectPrinter,
            //       child: const Text('Connect Printer'),
            //     ),
            //     const SizedBox(width: 12),
            //     ElevatedButton(
            //       onPressed: _printSample,
            //       child: const Text('Print Sample'),
            //     ),
            //   ],
            // ),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _connectPrinter,
                    child: const Text('Connect Printer'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _printSample,
                    child: const Text('Print Sample Text'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pickAndPrintImage,
                    child: const Text('Print Image'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///s
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:bluetooth_thermal_printer_pro/bluetooth_thermal_printer_pro.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:image_picker/image_picker.dart';

// void main() {
//   runApp(const MaterialApp(home: MyApp()));
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   String status = '';
//   List<String> devices = [];
//   String? selectedDevice;
//   final ImagePicker _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadStatus();
//     });
//   }

//   Future<void> _loadStatus() async {
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.bluetoothConnect,
//       Permission.bluetoothScan,
//       Permission.locationWhenInUse,
//       Permission.location,

//       Permission.photos,
//       Permission.storage,
//     ].request();

//     bool granted = statuses.values.every((s) => s.isGranted);
//     if (!granted) {
//       _showSnackBar('Bluetooth & Location permissions are required');
//       setState(() {
//         status = 'Permission denied';
//       });
//       return;
//     }

//     try {
//       final s = await BluetoothThermalPrinterPro.bluetoothStatus();
//       setState(() {
//         status = (s == 'true') ? 'Enabled' : 'Disabled';
//       });
//     } catch (e) {
//       setState(() {
//         status = 'Error checking Bluetooth';
//       });
//       _showSnackBar('Error: $e');
//     }

//     if (status == 'Enabled') {
//       try {
//         final list = await BluetoothThermalPrinterPro.getLinkedDevices();
//         setState(() {
//           devices = list;
//           if (list.isNotEmpty) selectedDevice = list[0];
//         });
//       } catch (e) {
//         _showSnackBar('Failed to load devices: $e');
//       }
//     }
//   }

//   Future<void> _connectPrinter() async {
//     if (selectedDevice == null) {
//       _showSnackBar('Select a device first');
//       return;
//     }

//     final mac = selectedDevice!.split('#').last;
//     final connected = await BluetoothThermalPrinterPro.connectPrinter(mac);
//     setState(() {
//       status = connected == 'true' ? 'Connected' : 'Disconnected';
//     });
//     _showSnackBar('Printer connection: $status');
//   }

//   Future<void> _printSample() async {
//     if (await BluetoothThermalPrinterPro.connectionStatus() != 'true') {
//       _showSnackBar('Printer not connected');
//       return;
//     }

//     const sampleText = '''
// === Sample Receipt ===
// Item 1       10.00
// Item 2       15.50
// ---------------------
// Total        25.50
// =====================
// ''';

//     final result = await BluetoothThermalPrinterPro.printText(sampleText);
//     _showSnackBar(result == 'true' ? 'Printed successfully' : 'Print failed');
//   }

//   Future<void> _pickAndPrintImage() async {
//     final picker = ImagePicker();
//     final XFile? file = await picker.pickImage(source: ImageSource.gallery);

//     if (file == null) {
//       _showSnackBar("No image selected");
//       return;
//     }

//     final Uint8List bytes = await file.readAsBytes();

//     if (await BluetoothThermalPrinterPro.connectionStatus() != 'true') {
//       _showSnackBar("Printer not connected");
//       return;
//     }

//     final result = await BluetoothThermalPrinterPro.printImage(bytes);
//     _showSnackBar(
//       result == 'true' ? "Image printed successfully" : "Image print failed",
//     );
//   }

//   void _showSnackBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('BT Printer Pro Example')),
//       body: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Bluetooth Status: $status'),
//             const SizedBox(height: 12),
//             const Text('Paired Devices:'),
//             DropdownButton<String>(
//               value: selectedDevice,
//               items: devices
//                   .map((d) => DropdownMenuItem(value: d, child: Text(d)))
//                   .toList(),
//               onChanged: (value) {
//                 setState(() {
//                   selectedDevice = value;
//                 });
//               },
//             ),
//             const SizedBox(height: 12),
//             Center(
//               child: Column(
//                 children: [
//                   ElevatedButton(
//                     onPressed: _connectPrinter,
//                     child: const Text('Connect Printer'),
//                   ),
//                   const SizedBox(width: 12),
//                   ElevatedButton(
//                     onPressed: _printSample,
//                     child: const Text('Print Sample Text'),
//                   ),
//                   const SizedBox(width: 12),
//                   ElevatedButton(
//                     onPressed: _pickAndPrintImage,
//                     child: const Text('Print Image'),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
