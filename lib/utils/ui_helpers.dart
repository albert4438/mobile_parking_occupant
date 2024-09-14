import 'package:flutter/material.dart';

Widget buildInfoRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Text(
          value ?? 'N/A',
          style: const TextStyle(
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}

Widget buildAddressSection(String? address) {
  return Container(
    padding: const EdgeInsets.all(12.0),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(color: Colors.grey[400]!),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on, color: Colors.blueAccent),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            address ?? 'Address not available',
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
      ],
    ),
  );
}
