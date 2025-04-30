import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '/services/admin_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool isProcessing = false;
  bool isScanned=false;

  void _onQRViewScanned(String scannedData) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    //Vibrate once on scan
    HapticFeedback.mediumImpact();

    //Show loader dialog
    _showLoaderDialog();

    final result = await AdminService.verifyOtp(scannedData);
    if(result!=Null){
      isScanned=true;
    }

    // Close loader dialog
    Navigator.of(context).pop();

    if (result.containsKey('message')) {
      _showDialog('QR Scanned', result['message']);
    } else if (result.containsKey('error')) {
      _showDialog('Error', result['error']);
    } else {
      _showDialog('Unexpected Response', result.toString());
    }

    setState(() => isProcessing = false);
  }

  void _showLoaderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Verifying..."),
          ],
        ),
      ),
    );
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
      ),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          for (final barcode in barcodeCapture.barcodes) {
            final String? code = barcode.rawValue;
            if (code != null && !isScanned) {
              _onQRViewScanned(code);
              break; // Process only the first valid barcode
            }
          }
        },
      ),
    );
  }
}
