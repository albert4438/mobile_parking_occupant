import 'package:flutter/material.dart';

Future<void> showAESKeyErrorDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
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
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15.0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 60.0,
            ),
            const SizedBox(height: 16.0),
            const Text(
              'AES Key Not Found',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10.0),
            const Text(
              'The encryption key required to scan QR codes is missing. Please ensure it is configured correctly.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              child: const Text('Retry'),
              onPressed: () {
                Navigator.pop(context);
                // Logic to reload AES key or retry
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showInvalidQRCodeErrorDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
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
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15.0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_rounded,
              color: Colors.orangeAccent,
              size: 60.0,
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Invalid QR Code',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10.0),
            const Text(
              'The scan was unsuccessful. Please try again with a valid QR Code.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              child: const Text('Scan Again'),
              onPressed: () {
                Navigator.pop(context);
                // Logic to restart the scan
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
