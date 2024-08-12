import 'package:http/http.dart' as http;
import 'dart:convert';

class ParkingLogRecord {
  static Future<void> recordLog({
    required int occupantId,
    required int vehicleId,
  }) async {
    try {
      // Check the last log to determine if it's a time_in or time_out
      final response = await http.get(
        Uri.parse('http://192.168.108.159:8080/parking_occupant/api/ParkingLog.php?occupantId=$occupantId&vehicleId=$vehicleId'),
      );

      if (response.statusCode == 200) {
        final lastLog = json.decode(response.body);
        final isTimeIn = lastLog['time_out'] == null;

        final logResponse = await http.post(
          Uri.parse('http://192.168.108.159:8080/parking_occupant/api/ParkingLog.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'occupantId': occupantId,
            'vehicleId': vehicleId,
            'isTimeIn': isTimeIn,
          }),
        );

        if (logResponse.statusCode == 200) {
          final result = json.decode(logResponse.body);
          if (result['success']) {
            print('Log recorded successfully');
          } else {
            print('Failed to record log: ${result['message']}');
          }
        } else {
          print('Failed to record log: HTTP status ${logResponse.statusCode}');
        }
      } else {
        print('Failed to check last log: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      print('Error recording log: $e');
    }
  }
}
