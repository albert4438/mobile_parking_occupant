import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Helper widget for contact options
Widget buildContactOption({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onPressed,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 28),
    label: Text(label, style: const TextStyle(fontSize: 16.0)),
    style: ElevatedButton.styleFrom(
      primary: color,
      onPrimary: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    ),
  );
}



// Function to make a phone call
Future<void> makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    throw 'Could not launch $launchUri';
  }
}

// Function to send an SMS
// Future<void> sendSMS(String phoneNumber) async {
//   final Uri launchUri = Uri(
//     scheme: 'sms',
//     path: phoneNumber,
//   );
//   if (await canLaunchUrl(launchUri)) {
//     await launchUrl(launchUri);
//   } else {
//     throw 'Could not launch $launchUri';
//   }
// }

Future<void> sendSMS(String phoneNumber, String message) async {
  final Uri launchUri = Uri(
    scheme: 'sms',
    path: phoneNumber,
    query: 'body=$message', // No encoding applied, passing plain text
  );
  
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    throw 'Could not launch $launchUri';
  }
}



