import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isFlashOn = false; // Local state for flash
  CameraFacing _currentCameraFacing = CameraFacing.back; // Local state for camera facing
  bool _isDetecting = true; // Flag to prevent multiple pops

  @override
  void dispose() {
    cameraController.dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.blueGrey[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            color: Colors.white,
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
              cameraController.toggleTorch();
            },
          ),
          IconButton(
            color: Colors.white,
            icon: Icon(
              _currentCameraFacing == CameraFacing.front
                  ? Icons.camera_front
                  : Icons.camera_rear,
            ),
            onPressed: () {
              setState(() {
                _currentCameraFacing = _currentCameraFacing == CameraFacing.front
                    ? CameraFacing.back
                    : CameraFacing.front;
              });
              cameraController.switchCamera();
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) async { // Made onDetect async
          if (!_isDetecting) return; // Prevent multiple detections/pops
          _isDetecting = false; // Set flag to false to prevent re-entry

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? scannedData = barcodes.first.rawValue;
            if (scannedData != null && scannedData.isNotEmpty) {
              // Stop the camera before popping the page
              await cameraController.stop();
              // Add a small delay to allow camera resources to release
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) { // Check if the widget is still in the tree before popping
                Navigator.pop(context, scannedData);
              }
            }
          }
        },
      ),
    );
  }
}
