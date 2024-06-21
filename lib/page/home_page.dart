import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences class
import 'login_page.dart';  // Make sure you have this import for LoginPage

class HomePage extends StatelessWidget {
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
                primary: Colors.blue, // Primary color
                onPrimary: Colors.white, // Text color
                elevation: 5, // Elevation
                padding: EdgeInsets.all(16), // Padding
              ),
              child: Text('Scan QR Code'),
              onPressed: () async {
                // Add QR code scanning functionality here
                // For example, using the `mobile_scanner` package
                //final qrCode = await MobileScanner.scan();

                // Handle the scanned QR code
                //print('Scanned QR code: $qrCode');
              },
            ),
            SizedBox(height: 20),
            // Parking Log Button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey), // Border color
                padding: EdgeInsets.all(16), // Padding
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
        itemCount: 10, // Replace with your parking log data
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
    return preferences.getBool(loginSharedPreference) ?? false;
  }
}
