import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionUtil {
  static String decryptData(String aesKey, String encryptedData) {
    try {
      final parts = encryptedData.split(':');
      final ivBase64 = parts[0];
      final encryptedBase64 = parts[1];
      final iv = base64.decode(ivBase64);
      final encryptedBytes = base64.decode(encryptedBase64);

      final key = encrypt.Key.fromBase16(aesKey);
      final ivObject = encrypt.IV(iv);

      final encrypter = encrypt.Encrypter(encrypt.AES(
        key,
        mode: encrypt.AESMode.cbc,
        padding: 'PKCS7',
      ));

      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(encryptedBytes),
        iv: ivObject,
      );

      return utf8.decode(decrypted);
    } catch (e) {
      print('Decryption error: $e');
      return 'Decryption failed';
    }
  }
}
