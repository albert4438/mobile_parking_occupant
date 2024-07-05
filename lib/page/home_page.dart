import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'login_page.dart';  
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart'; 

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _scanResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Guard App'),
        centerTitle: true,
        actions: [
          // Logout Button
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
            // QR Code Scanning Button
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
                  ScanMode.QR
                );

                if (scanResult != '-1') {
                  setState(() {
                    _scanResult = scanResult;
                  });

                  // Display the scan result
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Scan Result'),
                      content: Text(_scanResult),
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
              },
            ),
            SizedBox(height: 20),
            // Parking Log Button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey), 
                padding: EdgeInsets.all(16), 
              ),
              child: Text('View Parking Log'),
              onPressed: () {
                // Navigate to the parking log screen
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

// Parking Log Screen
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

// Shared Preferences class
class Shared {
  static String loginSharedPreference = "LOGGEDINKEY";

  static Future<bool> saveLoginSharedPreference(bool isLogin) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(loginSharedPreference, isLogin);
  }

  static Future<bool> getUserSharedPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool(loginSharedPreference)?? false;
  }
}