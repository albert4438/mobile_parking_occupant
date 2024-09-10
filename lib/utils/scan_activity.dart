import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
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
    String url = 'http://192.168.4.159:8080/parking_occupant/api/GetOccupantVehicleInfo.php';

    // Debugging: Log decryptedData before processing
    print('Decrypted Data before decoding: $decryptedData');

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
        final responseData = json.decode(response.body);
        print('Response Data: $responseData'); // Log the response data

        if (responseData.containsKey('data') && responseData['data'] != null) {
            return responseData;
        } else {
            throw Exception('No valid data found in response');
        }
    } else {
        throw Exception('Failed to load occupant and vehicle info');
    }
  }

}
