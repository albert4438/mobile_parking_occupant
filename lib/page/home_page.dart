import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:encrypt/encrypt.dart' as encrypt; // Import with a prefix
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert'; // Add this import
import 'login_page.dart';
import '../scan_activity.dart';
import '../enc-dec.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _scanResult = '';
  final _storage = FlutterSecureStorage();
  final String aesKey = '69788269e95b3f1df300f5f346fdfa63'; // Replace with your AES key, dapat dili hardCoded
  late String encryptionKey;
  String decryptedText = '';

  @override
  void initState() {
    super.initState();
    _loadEncryptionKey();
  }

  Future<void> _loadEncryptionKey() async {
    encryptionKey = await _storage.read(key: 'aes_key') ?? '';
    if (encryptionKey.isEmpty) {
      print('Encryption key is empty');
    } else {
      print('Encryption key loaded successfully');
    }
  }

  Future<void> _handleScan() async {
    String qrCodeData = await ScanActivity.scanQrCode(context);
    if (qrCodeData.isNotEmpty) {
      setState(() {
        decryptedText = EncryptionUtil.decryptData(aesKey, qrCodeData);
      });

      // Debugging: Print the decrypted data
      print('Decrypted Data: $decryptedText');

      // Display the decrypted data
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Scan Result'),
          content: Text(decryptedText.isNotEmpty ? decryptedText : 'Decryption failed or data is empty'),
          actions: [
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Guard App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Shared.saveLoginSharedPreference(false);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white,
                elevation: 5,
                padding: EdgeInsets.all(16),
              ),
              child: Text('Scan QR Code'),
              onPressed: _handleScan,
            ),
            SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey),
                padding: EdgeInsets.all(16),
              ),
              child: Text('View Parking Log'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ParkingLogScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ParkingLogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parking Log'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Parking Log Entry $index'),
            subtitle: Text('Date and Time'),
          );
        },
      ),
    );
  }
}

class Shared {
  static String loginSharedPreference = "LOGGEDINKEY";

  static Future<bool> saveLoginSharedPreference(bool isLogin) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(loginSharedPreference, isLogin);
  }

  static Future<bool> getUserSharedPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool(loginSharedPreference) ?? false;
  }
}
