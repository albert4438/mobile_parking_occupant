import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../scan_activity.dart';
import '../enc-dec.dart';
import '../parkinglogrecord.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _scanResult = '';
  final _storage = const FlutterSecureStorage();
  final String aesKey = '69788269e95b3f1df300f5f346fdfa63'; // Replace with your AES key
  late String encryptionKey;
  String decryptedText = '';
  Map<String, dynamic>? occupantVehicleInfo;
  late int personnelId; // Added personnelId to keep track of the logged-in personnel

  @override
  void initState() {
    super.initState();
    _loadEncryptionKey();
    _loadPersonnelId(); // Load personnel ID from SharedPreferences or another source
  }

  Future<void> _loadEncryptionKey() async {
    encryptionKey = await _storage.read(key: 'aes_key') ?? '';
    if (encryptionKey.isEmpty) {
      print('Encryption key is empty');
    } else {
      print('Encryption key loaded successfully');
    }
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
          builder: (context) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8.0),
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: const Text(
                      'Scan Result',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  if (occupantVehicleInfo != null && occupantVehicleInfo!['profilePicture'] != null)
                    Center(
                      child: CircleAvatar(
                        radius: 50.0,
                        backgroundImage: MemoryImage(base64Decode(occupantVehicleInfo!['profilePicture'])),
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  if (occupantVehicleInfo != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            '${occupantVehicleInfo!['Firstname']} ${occupantVehicleInfo!['Lastname']}',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        _buildInfoRow('OccupantBULOK', occupantVehicleInfo!['Occupant_ID']),
                        _buildInfoRow('VehicleBULOK', occupantVehicleInfo!['Vehicle_ID']),
                        _buildInfoRow('Firstname', occupantVehicleInfo!['Firstname']),
                        _buildInfoRow('Lastname', occupantVehicleInfo!['Lastname']),
                        _buildInfoRow('Phone Number', occupantVehicleInfo!['Phonenumber']),
                        _buildInfoRow('Address', occupantVehicleInfo!['Address']),
                        _buildInfoRow('Vehicle Type', occupantVehicleInfo!['Vehicle_Type']),
                        _buildInfoRow('Vehicle Color', occupantVehicleInfo!['Vehicle_Color']),
                        _buildInfoRow('Vehicle Plate Number', occupantVehicleInfo!['Vehicle_Platenumber']),
                        _buildInfoRow('Vehicle Model', occupantVehicleInfo!['Vehicle_Model']),
                        _buildInfoRow('Vehicle Brand', occupantVehicleInfo!['Vehicle_Brand']),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                        ElevatedButton(
                          onPressed: () async {
                            final occupantId = occupantVehicleInfo!['occupantId'] ?? occupantVehicleInfo!['Occupant_ID'] as int?;
                            final vehicleId = occupantVehicleInfo!['vehicleId'] ?? occupantVehicleInfo!['Vehicle_ID'] as int?;

                            print('Occupant ID: $occupantId'); // Log Occupant ID
                            print('Vehicle ID: $vehicleId');   // Log Vehicle ID

                            if (occupantId != null && vehicleId != null) {
                              // Fetch the last action type for the vehicle
                              String? lastActionType = await ParkingLogRecord.fetchLastActionType(vehicleId);

                              // Determine the new action type
                              String actionType = lastActionType == null || lastActionType == 'EXIT' ? 'ENTRY' : 'EXIT';

                              await ParkingLogRecord.recordLog(
                                occupantId: occupantId,
                                vehicleId: vehicleId,
                                actionType: actionType,
                                personnelId: personnelId,
                              );
                            } else {
                              print('Invalid data: occupantId or vehicleId is null');
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('YES'),
                        ),


                            const SizedBox(width: 16.0),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('NO'),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    const Center(child: Text('No data found')),
                  const SizedBox(height: 16.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue,
                        onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        print('Error fetching info: $e');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to fetch occupant and vehicle info. Error: $e'),
            actions: [
              ElevatedButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white,
                elevation: 5,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Scan QR Code'),
              onPressed: _handleScan,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('View Parking Log'),
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
