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
  late int personnelId; // Added personnelId to keep track of the logged-in personnel

  @override
    void initState() {
      super.initState();
      
      try {
        aesKey = Environment.aesKey;  // Attempt to retrieve AES key from environment
        if (aesKey.isEmpty) {
          throw Exception('AES key is missing.');
        } else {
          print('AES Key loaded successfully: $aesKey');
        }
      } catch (e) {
        print('Error loading AES key: $e');
        _showAESKeyErrorDialog();  // Show error dialog if AES key is missing
      }

      _loadPersonnelId(); // Load personnel ID from SharedPreferences or another source
    }



  Future<void> _loadPersonnelId() async {
    // Assuming personnelId is stored in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      personnelId = prefs.getInt('personnel_id') ?? 0;
    });
  }

  Future<void> _handleScan() async {
    String qrCodeData = await ScanActivity.scanQrCode(context);

    if (qrCodeData.isNotEmpty) {
      setState(() {
        decryptedText = EncryptionUtil.decryptData(aesKey, qrCodeData);
      });

      print('Decrypted Data: $decryptedText');

      // Check if the decrypted text is empty or invalid
      if (decryptedText.isEmpty) {
        _showInvalidQRCodeErrorDialog(); // Show invalid QR code error dialog
        return; // Stop execution if the QR code is invalid
      }

      try {
        final info = await ScanActivity.fetchOccupantVehicleInfo(decryptedText);
        setState(() {
          occupantVehicleInfo = info['data'];
        });

        print('Occupant Vehicle Info: $occupantVehicleInfo'); // Log the info

        if (occupantVehicleInfo == null || occupantVehicleInfo!.isEmpty) {
            throw Exception("Failed to fetch occupant or vehicle information.");
        }

          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20.0,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'Scan Result',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    if (occupantVehicleInfo != null)
                      Center(
                        child: Column(
                          children: [
                            if (occupantVehicleInfo!['profilePicture'] != null)
                              CircleAvatar(
                                radius: 60.0,
                                backgroundImage: MemoryImage(base64Decode(occupantVehicleInfo!['profilePicture'])),
                              ),
                            const SizedBox(height: 16.0),
                            Text(
                              '${occupantVehicleInfo!['Firstname']} ${occupantVehicleInfo!['Lastname']}',
                              style: const TextStyle(
                                fontSize: 22.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10.0),

                            // Tap Gesture on Phone Number to show second dialog
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0), // Sleeker, modern corner radius
                                    ),
                                    elevation: 8, // Slight elevation for a premium feel
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 30.0,
                                            offset: Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Header with icon and title
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.phone_android, size: 40, color: Colors.blueAccent),
                                              const SizedBox(width: 10.0),
                                              Text(
                                                'Contact Options',
                                                style: TextStyle(
                                                  fontSize: 22.0,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 25.0),

                                          // Call and Text buttons
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _buildContactOption(
                                                icon: Icons.phone,
                                                label: 'Call',
                                                color: Colors.green,
                                                onPressed: () {
                                                  final phoneNumber = occupantVehicleInfo!['Phonenumber'];
                                                  if (phoneNumber != null) {
                                                    _makePhoneCall(phoneNumber);
                                                  }
                                                },
                                              ),
                                              _buildContactOption(
                                                icon: Icons.message,
                                                label: 'Text',
                                                color: Colors.blueAccent,
                                                onPressed: () {
                                                  final phoneNumber = occupantVehicleInfo!['Phonenumber'];
                                                  if (phoneNumber != null) {
                                                    _sendSMS(phoneNumber);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 30.0),

                                          // Cancel button
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context); // Close dialog
                                              },
                                              child: const Text('Cancel'),
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 14.0),
                                                primary: Colors.redAccent,
                                                onPrimary: Colors.white,
                                                textStyle: TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(30.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: _buildInfoRow('Phone Number', occupantVehicleInfo!['Phonenumber']),
                            ),

                            _buildInfoRow('Vehicle Type', occupantVehicleInfo!['Vehicle_Type']),
                            _buildInfoRow('Vehicle Color', occupantVehicleInfo!['Vehicle_Color']),
                            _buildInfoRow('Plate Number', occupantVehicleInfo!['Vehicle_Platenumber']),
                            _buildInfoRow('Model', occupantVehicleInfo!['Vehicle_Model']),
                            _buildInfoRow('Brand', occupantVehicleInfo!['Vehicle_Brand']),
                            const SizedBox(height: 20.0),
                            _buildAddressSection(occupantVehicleInfo!['Address']),
                            const SizedBox(height: 20.0),
                            Text(
                              'Do you want to log this entry?',
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      const Center(child: Text('No data found')),

                    const SizedBox(height: 20.0),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final occupantId = occupantVehicleInfo!['occupantId'] ?? occupantVehicleInfo!['Occupant_ID'] as int?;
                            final vehicleId = occupantVehicleInfo!['vehicleId'] ?? occupantVehicleInfo!['Vehicle_ID'] as int?;

                            if (occupantId != null && vehicleId != null) {
                              String? lastActionType = await ParkingLogRecord.fetchLastActionType(vehicleId);
                              String actionType = lastActionType == null || lastActionType == 'EXIT' ? 'ENTRY' : 'EXIT';
                              await ParkingLogRecord.recordLog(
                                occupantId: occupantId,
                                vehicleId: vehicleId,
                                actionType: actionType,
                                personnelId: personnelId,
                              );

                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  Color iconColor = actionType == 'ENTRY' ? Colors.blueAccent : Colors.redAccent;
                                  Color actionTypeColor = actionType == 'ENTRY' ? Colors.blueAccent : Colors.redAccent;

                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      padding: const EdgeInsets.all(20.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 15.0,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            color: iconColor,
                                            size: 60.0,
                                          ),
                                          const SizedBox(height: 16.0),
                                          Text(
                                            'Log Successful',
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 22.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 10.0),
                                          RichText(
                                            textAlign: TextAlign.center,
                                            text: TextSpan(
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 16.0,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'The entry has been logged as ',
                                                ),
                                                TextSpan(
                                                  text: actionType,
                                                  style: TextStyle(
                                                    color: actionTypeColor,
                                                    fontSize: 16.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: '.',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 20.0),
                                          ElevatedButton(
                                            child: const Text('OK'),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              primary: Colors.blueAccent,
                                              onPrimary: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8.0),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                          child: const Text('Confirm'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.blueAccent,
                            onPrimary: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.redAccent,
                            onPrimary: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );



      } catch (e) {
        print('Error fetching info: $e');
         _showInvalidQRCodeErrorDialog();
        // showDialog(
        //   context: context,
        //   builder: (context) => AlertDialog(
        //     title: const Text('Error'),
        //     content: Text('Failed to fetch occupant and vehicle info. Error: $e'),
        //     actions: [
        //       ElevatedButton(
        //         child: const Text('OK'),
        //         onPressed: () {
        //           Navigator.pop(context);
        //         },
        //       ),
        //     ],
        //   ),
        // );
      }
    }
  }

// AES Key Not Found Error Dialog
void _showAESKeyErrorDialog() {
  showAESKeyErrorDialog(context);
}

// Invalid QR Code Error Dialog
void _showInvalidQRCodeErrorDialog() {
  showInvalidQRCodeErrorDialog(context);
}

// Function to make a phone call
void _makePhoneCall(String phoneNumber) {
  makePhoneCall(phoneNumber);
}

// Function to send an SMS
void _sendSMS(String phoneNumber) {
  sendSMS(phoneNumber);
}

// For displaying information rows
Widget _buildInfoRow(String label, String? value) {
  return buildInfoRow(label, value);
}

// For displaying the address section
Widget _buildAddressSection(String? address) {
  return buildAddressSection(address);
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
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60), // Full-width button
                primary: Colors.blue,
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
              onPressed: _handleScan,
            ),

            const SizedBox(height: 20),
                OutlinedButton.icon(
                  icon: const Icon(Icons.list),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60), // Full-width button
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

// Helper widget for contact options
Widget _buildContactOption({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onPressed,
}) {
  return buildContactOption(icon: icon, label: label, color: color, onPressed: onPressed);
}

class ParkingLogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Log'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: 10, // Adjust according to the actual data
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Parking Log Entry $index'),
            subtitle: const Text('Date and Time'),
          );
        },
      ),
    );
  }
}


