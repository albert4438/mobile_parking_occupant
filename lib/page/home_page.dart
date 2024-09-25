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
import '../utils/parking_lot_dropdown.dart';

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
  int? selectedParkingLot;  // Changed to int?
  List<Map<String, dynamic>> parkingLots = []; // List of parking lots with ID and Name
  bool isScanButtonEnabled = false; // Disable the scan button by default

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

      _fetchParkingLots();  // Fetch the available parking lots
      _loadPersonnelId(); // Load personnel ID from SharedPreferences or another source
    }

  Future<void> _loadPersonnelId() async {
    // Assuming personnelId is stored in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      personnelId = prefs.getInt('personnel_id') ?? 0;
    });
  }
 
  Future<void> _fetchParkingLots() async {
          const String url = 'http://192.168.94.159:8080/parking_occupant/api/fetchParkingLots.php';
          try {
            final response = await http.get(Uri.parse(url));
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              if (data['success']) {
                setState(() {
                  parkingLots = List<Map<String, dynamic>>.from(data['parking_lots']);
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

  Future<void> _handleScan() async {
    if (selectedParkingLot == null) {
      print('No parking lot selected');
      return;
    }

    
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
          //Scan Result Dialog, Contact Dialog, Success Dialog
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

                            // Contact Icon Phone Number to show second dialog
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [

                                  // Display the phone number directly without extra spacing
                                  Text(
                                    occupantVehicleInfo!['Phonenumber'] ?? 'No phone number available',
                                    style: TextStyle(fontSize: 16.0, color: Colors.black87),
                                  ),

                                  // Contact icon button before the phone number
                                  IconButton(
                                    icon: Icon(Icons.contact_phone, color: Colors.blueAccent),
                                    onPressed: () {
                                      // Trigger the dialog for call or text
                                      showDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20.0),
                                          ),
                                          elevation: 8,
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
                                                        final occupantName = "${occupantVehicleInfo!['Firstname']} ${occupantVehicleInfo!['Lastname']}";
                                                        if (phoneNumber != null) {
                                                          _showMessageSelectionDialog(phoneNumber, occupantName);
                                                        }
                                                      },
                                                    ),

                                                  ],
                                                ),
                                                const SizedBox(height: 30.0),
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
                                  ),
                                ],
                              ),
                            ),

           
                            _buildInfoRow('Plate Number', occupantVehicleInfo!['Vehicle_Platenumber']),
                            _buildInfoRow('Vehicle Type', occupantVehicleInfo!['Vehicle_Type']),
                            _buildInfoRow('Vehicle Color', occupantVehicleInfo!['Vehicle_Color']),
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

                            if (occupantId != null && vehicleId != null && selectedParkingLot != null) {
                              String? lastActionType = await ParkingLogRecord.fetchLastActionType(vehicleId);
                              String actionType = lastActionType == null || lastActionType == 'EXIT' ? 'ENTRY' : 'EXIT';
                              await ParkingLogRecord.recordLog(
                                occupantId: occupantId,
                                vehicleId: vehicleId,
                                actionType: actionType,
                                personnelId: personnelId,
                                parkingLotId: selectedParkingLot!,
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
void _sendSMS(String phoneNumber, String message) {
  sendSMS(phoneNumber, message);
}

// List of predefined messages
List<String> readyMadeMessages = [
  // General notification for vehicle attention
  "Hi {name}, your vehicle (Plate: {plate}, Brand: {brand}, Model: {model}, Color: {color}) is currently blocking other vehicles. Please move it immediately.",

  // Urgent maintenance or safety issue
  "Hi {name}, urgent: there is a safety concern with your vehicle (Plate: {plate}, Brand: {brand}, Model: {model}, Color: {color}). Please return to the parking lot now.",

  // Incorrect parking spot
  "Hi {name}, it appears your vehicle (Plate: {plate}, Brand: {brand}, Model: {model}, Color: {color}) is parked in the wrong spot. Please move it to the correct location.",

  // Unauthorized vehicle
  "Hi {name}, your vehicle (Plate: {plate}, Brand: {brand}, Model: {model}, Color: {color}) is not authorized to park here. Please remove it as soon as possible.",

  // Blocked access to an emergency exit
  "Hi {name}, your vehicle (Plate: {plate}, Brand: {brand}, Model: {model}, Color: {color}) is blocking an emergency exit. Please return to the parking lot and move it immediately.",

  // Notification after a parking lot accident
  "Hi {name}, there has been a minor incident involving your vehicle (Plate: {plate}, Brand: {brand}, Model: {model}, Color: {color}). Please return to the parking lot for more details.",

 ];

void _showMessageSelectionDialog(String phoneNumber, String occupantName) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        backgroundColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double screenHeight = MediaQuery.of(context).size.height;

            // Get the vehicle info
            String plate = occupantVehicleInfo?['Vehicle_Platenumber'] ?? 'Unknown';
            String brand = occupantVehicleInfo?['Vehicle_Brand'] ?? 'Unknown';
            String model = occupantVehicleInfo?['Vehicle_Model'] ?? 'Unknown';
            String color = occupantVehicleInfo?['Vehicle_Color'] ?? 'Unknown';

            return Center(
              child: Container(
                width: constraints.maxWidth * 0.9, // Adaptive width
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20.0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Adjust height to fit within the screen, accounting for padding
                    maxHeight: screenHeight * 0.85,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Text(
                          'Choose a Message',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Instruction
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: const Text(
                          'Tap a message to send:',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10.0),

                      // Message List with scroll functionality
                      Expanded(
                        child: Scrollbar(
                          thickness: 5.0,
                          child: ListView.builder(
                            itemCount: readyMadeMessages.length,
                            itemBuilder: (context, index) {
                              String message = readyMadeMessages[index]
                                  .replaceAll("{name}", occupantName)
                                  .replaceAll("{plate}", plate)
                                  .replaceAll("{brand}", brand)
                                  .replaceAll("{model}", model)
                                  .replaceAll("{color}", color);

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12.0),
                                  title: Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  onTap: () {
                                    sendSMS(phoneNumber, message); // Send the selected message
                                    Navigator.pop(context); // Close dialog
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Cancel Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            primary: Colors.redAccent,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
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
        ),
      );
    },
  );
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

            // Dropdown for selecting parking lot
            ParkingLotDropdown(
              parkingLots: parkingLots,
              onParkingLotSelected: (int? parkingLotId) {
                setState(() {
                  selectedParkingLot = parkingLotId;
                });
              },
            ),
            const SizedBox(height: 20),


              // Scan button
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  primary: selectedParkingLot != null ? Colors.blue : Colors.grey, // Color based on selectedParkingLot
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
                onPressed: selectedParkingLot != null ? _handleScan : null, // Enable/disable based on selectedParkingLot
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




