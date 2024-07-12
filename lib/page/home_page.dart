import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:encrypt/encrypt.dart' as encrypt; // Import with a prefix
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert'; // Add this import
import 'dart:typed_data'; // Add this import

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _scanResult = '';
  final _storage = FlutterSecureStorage();
  late String encryptionKey;

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

  String decrypt(String encrypted, String encryptionKey) {
    final encryptionKeyBytes = base64Decode(encryptionKey);
    if (encryptionKeyBytes.length != 16) {
      throw ArgumentError('Key length is not 128 bits');
    }

    final key = encrypt.Key(encryptionKeyBytes);
    final iv = encrypt.IV.fromLength(16); // Ensure this matches the IV used during encryption
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    try {
      final decrypted = encrypter.decrypt64(encrypted, iv: iv);
      return decrypted;
    } catch (error) {
      print('Decryption error: $error');
      return '';
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
              onPressed: () async {
                String scanResult = await FlutterBarcodeScanner.scanBarcode(
                  '#ff6666',
                  'Cancel',
                  true,
                  ScanMode.QR,
                );

                if (scanResult != '-1') {
                  setState(() {
                    _scanResult = scanResult;
                  });

                  // Debugging: Print the scanned QR code data
                  print('Scanned QR Code: $_scanResult');

                  // Decrypt the scan result
                  try {
                    final decryptedData = decrypt(_scanResult, encryptionKey);

                    // Debugging: Print the decrypted data
                    print('Decrypted Data: $decryptedData');

                    // Display the decrypted data
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Scan Result'),
                        content: Text(decryptedData.isNotEmpty ? decryptedData : 'Decryption failed or data is empty'),
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
                  } catch (error) {
                    // Debugging: Print the error message
                    print('Decryption error: $error');
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Error'),
                        content: Text('Failed to decrypt data. Please ensure the QR code is valid and the encryption key is correct.'),
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
              },
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
