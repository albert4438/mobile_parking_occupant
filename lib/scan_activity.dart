import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  static Future<Map<String, dynamic>> fetchOccupantVehicleInfo(String decryptedData) async {
    String url = 'http://192.168.252.160:8080/parking_occupant/api/GetOccupantVehicleInfo.php';

    // Ensure decryptedData is a valid JSON string
    Map<String, dynamic> requestData;
    try {
      requestData = json.decode(decryptedData);
    } catch (e) {
      throw Exception('Decrypted data is not a valid JSON string');
    }

    // Debugging: Log the request data
    print('Sending request data: $requestData');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    );

    // Debugging: Log the response status and body
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load occupant and vehicle info');
    }
  }

}
