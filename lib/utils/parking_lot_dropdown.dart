import 'package:flutter/material.dart';

class ParkingLotDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> parkingLots;
  final Function(int?) onParkingLotSelected;

  const ParkingLotDropdown({
    required this.parkingLots,
    required this.onParkingLotSelected,
    Key? key,
  }) : super(key: key);

  @override
  _ParkingLotDropdownState createState() => _ParkingLotDropdownState();
}

class _ParkingLotDropdownState extends State<ParkingLotDropdown> {
  int? selectedParkingLot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Select Parking Lot',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        GestureDetector(
          onTap: () {
            // Open dropdown on tap
            _showParkingLotPicker(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10.0,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedParkingLot != null
                      ? widget.parkingLots
                          .firstWhere((lot) => lot['Parking_lot_ID'] == selectedParkingLot)['Parking_Lot_Name']
                      : 'Choose a Parking Lot',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 30.0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Function to show the custom dropdown picker
  void _showParkingLotPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20.0,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                ),
                child: Text(
                  'Select Parking Lot',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.parkingLots.length,
                  itemBuilder: (context, index) {
                    final lot = widget.parkingLots[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedParkingLot = lot['Parking_lot_ID'];
                        });
                        widget.onParkingLotSelected(selectedParkingLot);
                        Navigator.pop(context); // Close the bottom sheet
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                        decoration: BoxDecoration(
                          color: selectedParkingLot == lot['Parking_lot_ID']
                              ? Colors.lightBlueAccent.withOpacity(0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: selectedParkingLot == lot['Parking_lot_ID'] ? Colors.blueAccent : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lot['Parking_Lot_Name'],
                              style: TextStyle(
                                fontSize: 16.0,
                                color: selectedParkingLot == lot['Parking_lot_ID']
                                    ? Colors.blueAccent
                                    : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (selectedParkingLot == lot['Parking_lot_ID'])
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blueAccent,
                                size: 24.0,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
