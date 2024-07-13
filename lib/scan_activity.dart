import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class ScanActivity {
  static Future<String> scanQrCode(BuildContext context) async {
    try {
      String qrCodeData = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.QR,
      );

      if (qrCodeData != '-1') {
        return qrCodeData;
      } else {
        return '';
      }
    } catch (e) {
      print('Error scanning QR code: $e');
      return '';
    }
  }
}
