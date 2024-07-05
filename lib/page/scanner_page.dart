import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class ScannerPage extends StatefulWidget {
  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String _scanResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Scanner'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _scanResult,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Scan QR Code'),
              onPressed: () async {
                String scanResult = await FlutterBarcodeScanner.scanBarcode(
                  '#ff6666', 
                  'Cancel', 
                  true, 
                  ScanMode.QR
                );

                setState(() {
                  _scanResult = scanResult;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}