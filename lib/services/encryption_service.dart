import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static const int _iterations = 10000;
  static const int _keyLength = 32; // AES-256
  static const int _ivLength = 16;  // 128 位

  /// 派生密钥
  static Uint8List _deriveKey(String password, String date) {
    final salt = utf8.encode('CipherDiarySalt:$date');
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _iterations, _keyLength));
    return derivator.process(utf8.encode(password));
  }

  /// 生成安全随机字节
  static Uint8List _secureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  /// 加密，输出 `日期|Base64(IV + 密文)`
  static String encrypt(String plainText, String date, String password) {
    final key = _deriveKey(password, date);
    final iv = _secureRandomBytes(_ivLength);

    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(key), iv));

    final plainBytes = utf8.encode(plainText);
    final encrypted = _processBlocks(cipher, plainBytes, encrypting: true);

    final combined = Uint8List.fromList(iv + encrypted);
    return '$date|${base64.encode(combined)}';
  }

  /// 解密
  static String decrypt(String fullCipher, String password) {
    if (fullCipher.length < 9 || fullCipher[8] != '|') {
      throw FormatException('密文格式错误');
    }
    final date = fullCipher.substring(0, 8);
    final pure = fullCipher.substring(9);

    final key = _deriveKey(password, date);
    final combined = base64.decode(pure);
    if (combined.length < _ivLength) throw FormatException('密文数据不完整');

    final iv = combined.sublist(0, _ivLength);
    final encryptedBytes = combined.sublist(_ivLength);

    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), iv));

    final decrypted = _processBlocks(cipher, encryptedBytes, encrypting: false);
    return utf8.decode(decrypted);
  }

  /// 分块处理（自动 PKCS7 填充/去填充）
  static Uint8List _processBlocks(
    BlockCipher cipher,
    Uint8List data, {
    required bool encrypting,
  }) {
    Uint8List workData;
    if (encrypting) {
      workData = _pad(data, cipher.blockSize);
    } else {
      workData = data;
    }

    final out = Uint8List(workData.length);
    for (var offset = 0; offset < workData.length; offset += cipher.blockSize) {
      cipher.processBlock(workData, offset, out, offset);
    }

    if (!encrypting) {
      return _unpad(out);
    }
    return out;
  }

  /// PKCS7 填充
  static Uint8List _pad(Uint8List data, int blockSize) {
    final padLen = blockSize - (data.length % blockSize);
    final padded = Uint8List(data.length + padLen);
    padded.setRange(0, data.length, data);
    for (var i = data.length; i < padded.length; i++) {
      padded[i] = padLen;
    }
    return padded;
  }

  /// 去除填充
  static Uint8List _unpad(Uint8List data) {
    final padLen = data[data.length - 1];
    return data.sublist(0, data.length - padLen);
  }
}