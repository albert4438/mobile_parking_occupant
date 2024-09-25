import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/scan_activity.dart';
import '../utils/enc-dec.dart';
import '../utils/parkinglogrecord.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';  // Import dotenv
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_application_1/model/environment.dart'; 
import './parking_log_page.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package
import '../utils/dialog_helpers.dart';
import '../utils/contact_options.dart';
import '../utils/ui_helpers.dart';
import '../utils/shared_preferences_util.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _scanResult = '';
  String decryptedText = '';
  late String aesKey;
  Map<String, dynamic>? occupantVehicleInfo;
  late int personnelId;
  String? selectedParkingLot;  // Add selectedParkingLot to hold the selected parking lot
  List<String> parkingLots = []; // List of parking lots
  bool isScanButtonEnabled = false; // Disable the scan button by default

  @override
  void initState() {
    super.initState();
    _fetchParkingLots();  // Fetch the available parking lots
    _loadPersonnelId(); // Load personnel ID
  }

  // Fetch available parking lots from the server
  Future<void> _fetchParkingLots() async {
    const String url = 'http://your-server-address/fetchParkingLots.php';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            parkingLots = List<String>.from(data['parking_lots']);
          });
        } else {
          print('Failed to fetch parking lots');
        }
      } else {
        print('Failed to fetch parking lots');
      }
    } catch (e) {
      print('Error fetching parking lots: $e');
    }
  }

  Future<void> _loadPersonnelId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      personnelId = prefs.getInt('personnel_id') ?? 0;
    });
  }

  Future<void> _handleScan() async {
    if (selectedParkingLot == null) {
      print('No parking lot selected');
      return;
    }

    String qrCodeData = await ScanActivity.scanQrCode(context);
    // Handle the scanning logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
            
            // Dropdown for selecting parking lot
            DropdownButton<String>(
              hint: const Text('Select Parking Lot'),
              value: selectedParkingLot,
              onChanged: (String? newValue) {
                setState(() {
                  selectedParkingLot = newValue;
                  isScanButtonEnabled = selectedParkingLot != null; // Enable the scan button if a parking lot is selected
                });
              },
              items: parkingLots.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Scan button
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                primary: isScanButtonEnabled ? Colors.blue : Colors.grey, // Change color based on enabled/disabled state
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              label: const Text(
                'Scan QR Code',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: isScanButtonEnabled ? _handleScan : null, // Disable if no parking lot selected
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              icon: const Icon(Icons.list),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: const Text(
                'View Parking Log',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ParkingLogPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class ParkingLogRecord {
//   static Future<void> recordLog({
//     required int occupantId,
//     required int vehicleId,
//     required String actionType,
//     required int personnelId,
//     required String parkingLotId,  // Add parkingLotId as a required parameter
//   }) async {
//     final String url = 'http://192.168.4.159:8080/parking_occupant/api/GetLastActionType.php'; // Ensure this URL is correct

//     final Map<String, dynamic> data = {
//       'occupant_id': occupantId,
//       'vehicle_id': vehicleId,
//       'action_type': actionType,
//       'personnel_id': personnelId,
//       'parking_lot_id': parkingLotId,  // Include the parking lot in the request
//     };

//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(data),
//       );

//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['success']) {
//           print('Log recorded successfully');
//         } else {
//           print('Failed to record log: ${responseData['message']}');
//         }
//       } else {
//         print('Failed to record log: ${response.statusCode} ${response.body}');
//       }
//     } catch (e) {
//       print('Error recording log: $e');
//     }
//   }
// }

