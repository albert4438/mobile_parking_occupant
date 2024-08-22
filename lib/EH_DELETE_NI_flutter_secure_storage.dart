import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> storeKey() async {
    await _storage.write(key: 'aes_key', value: '69788269e95b3f1df300f5f346fdfa63');
  }

  Future<String?> getKey() async {
    return await _storage.read(key: 'aes_key');
  }
}