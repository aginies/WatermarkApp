import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionUtils {
  static int crc16(List<int> data) {
    var crc = 0xFFFF;
    for (var b in data) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc;
  }

  static Uint8List encryptBytes(Uint8List data, String password) {
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);

    final result = BytesBuilder();
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    return result.toBytes();
  }

  static Uint8List? decryptBytes(Uint8List encryptedData, String password) {
    try {
      if (encryptedData.length < 32) {
        // 16 bytes IV + at least 16 bytes payload (one block)
        return null;
      }
      final iv = enc.IV(encryptedData.sublist(0, 16));
      final ciphertext = encryptedData.sublist(16);

      // Ensure ciphertext is a multiple of 16
      if (ciphertext.length % 16 != 0) {
        return null;
      }

      final keyBytes = sha256.convert(utf8.encode(password)).bytes;
      final key = enc.Key(Uint8List.fromList(keyBytes));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted =
          encrypter.decryptBytes(enc.Encrypted(ciphertext), iv: iv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      debugPrint('Decryption error: $e');
      return null;
    }
  }
}
