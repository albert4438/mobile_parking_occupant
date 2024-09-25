import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ParkingLogPage extends StatefulWidget {
  @override
  _ParkingLogPageState createState() => _ParkingLogPageState();
}

class _ParkingLogPageState extends State<ParkingLogPage> {
  List<dynamic> parkingLogs = [];
  List<dynamic> filteredLogs = [];
  bool isLoading = true;
  String? errorMessage;

  String searchKeyword = '';
  String actionTypeFilter = 'All';
  DateTimeRange? dateRangeFilter;
  String sortOption = 'Date: Latest First';

  // Helper method to get color based on action type
  Color _getActionColor(String actionType) {
    if (actionType == 'ENTRY') {
      return Colors.green; // Green for ENTRY
    } else if (actionType == 'EXIT') {
      return Colors.red; // Red for EXIT
    } else {
      return Colors.black; // Default color
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchParkingLogs();
  }

  Future<void> _fetchParkingLogs() async {
    const String url = 'http://192.168.94.159:8080/parking_occupant/api/fetchParkingLogs.php';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            parkingLogs = data['logs'];
            filteredLogs = parkingLogs;
            isLoading = false;
          });
        } else {
          _handleError('Failed to fetch parking logs.');
        }
      } else {
        _handleError('Error fetching data: ${response.statusCode}');
      }
    } catch (e) {
      _handleError('Error: $e');
    }
  }

  void _handleError(String message) {
    setState(() {
      errorMessage = message;
      isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      filteredLogs = parkingLogs.where((log) {
        final matchesKeyword = searchKeyword.isEmpty ||
            log['vehicle'].toLowerCase().contains(searchKeyword.toLowerCase()) ||
            log['personnel_fullname'].toLowerCase().contains(searchKeyword.toLowerCase()) ||
            log['occupant_fullname'].toLowerCase().contains(searchKeyword.toLowerCase());

        final matchesActionType = actionTypeFilter == 'All' || log['action_type'] == actionTypeFilter;

        final matchesDateRange = dateRangeFilter == null ||
            (DateTime.parse(log['timestamp']).isAfter(dateRangeFilter!.start) &&
                DateTime.parse(log['timestamp']).isBefore(dateRangeFilter!.end));

        return matchesKeyword && matchesActionType && matchesDateRange;
      }).toList();

      // Apply sorting
      if (sortOption == 'Date: Latest First') {
        filteredLogs.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      } else {
        filteredLogs.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
      }
    });
  }

  void _resetFilters() {
    setState(() {
      searchKeyword = '';
      actionTypeFilter = 'All';
      dateRangeFilter = null;
      sortOption = 'Date: Latest First';
      filteredLogs = parkingLogs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Log'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Search by keyword',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchKeyword = value;
                                  _applyFilters();
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          DropdownButton<String>(
                            value: actionTypeFilter,
                            items: ['All', 'ENTRY', 'EXIT'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                actionTypeFilter = newValue!;
                                _applyFilters();
                              });
                            },
                          ),
                          SizedBox(width: 10),
                          DropdownButton<String>(
                            value: sortOption,
                            items: ['Date: Latest First', 'Date: Oldest First'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                sortOption = newValue!;
                                _applyFilters();
                              });
                            },
                          ),
                        ],
                      ),
                    ),


                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            child: ListTile(
                              title: Text(
                                'Vehicle: ${log['vehicle']}',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      text: 'Occupant: ',
                                      style: TextStyle(fontSize: 16, color: Colors.black),
                                      children: [
                                        TextSpan(
                                          text: log['occupant_fullname'],
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      text: 'Parking Lot: ', // New field for parking lot
                                      style: TextStyle(fontSize: 16, color: Colors.black),
                                      children: [
                                        TextSpan(
                                          text: log['parking_lot_name'], // Bind parking lot data
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      text: 'Action: ',
                                      style: TextStyle(fontSize: 16, color: _getActionColor(log['action_type'])),
                                      children: [
                                        TextSpan(
                                          text: log['action_type'],
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      text: 'Date: ',
                                      style: TextStyle(fontSize: 16, color: Colors.black),
                                      children: [
                                        TextSpan(
                                          text: log['timestamp'],
                                          style: TextStyle(fontWeight: FontWeight.normal),
                                        ),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      text: 'Scanned by: ',
                                      style: TextStyle(fontSize: 16, color: Colors.black),
                                      children: [
                                        TextSpan(
                                          text: log['personnel_fullname'],
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),


                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _resetFilters,
                        child: const Text('Reset Filters'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
