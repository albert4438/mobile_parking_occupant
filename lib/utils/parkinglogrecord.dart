import 'package:http/http.dart' as http;
import 'dart:convert';

class ParkingLogRecord {
  static Future<void> recordLog({
    required int occupantId,
    required int vehicleId,
    required String actionType,
    required int personnelId,
  }) async {
    final String url = 'http://192.168.4.159:8080/parking_occupant/api/RecordParkingLog.php'; // Ensure this URL is correct

    final Map<String, dynamic> data = {
      'occupant_id': occupantId,
      'vehicle_id': vehicleId,
      'action_type': actionType,
      'personnel_id': personnelId
    };

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (response.statusCode == 200) {
          try {
            final responseData = json.decode(response.body);
            if (responseData['success']) {
              print('Log recorded successfully');
            } else {
              print('Failed to record log: ${responseData['message']}');
            }
          } catch (e) {
            print('Failed to parse JSON response: ${response.body}');
          }
        } else {
          print('Failed to record log: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        print('Error recording log: $e');
      }

  }


  // In the ParkingLogRecord class

  static Future<String?> fetchLastActionType(int vehicleId) async {
  final String url = 'http://192.168.4.159:8080/parking_occupant/api/GetLastActionType.php'; // Ensure this URL is correct

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'vehicle_id': vehicleId}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        return responseData['last_action_type'];
      } else {
        print('Failed to fetch last action type: ${responseData['message']}');
      }
    } else {
      print('Failed to fetch last action type: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    print('Error fetching last action type: $e');
  }
  return null; // Return null if there's an error or no action type found
}

}




