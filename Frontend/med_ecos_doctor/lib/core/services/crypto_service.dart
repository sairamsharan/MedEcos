import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides RSA-2048 digital signature functionality for doctor prescriptions.
///
/// Architecture:
///   • The doctor has an RSA-2048 key pair generated once on first use.
///   • The private key is encrypted with AES-256-CBC, key-derived from the
///     doctor's password via PBKDF2-HMAC-SHA256, then stored in secure storage.
///   • The public key is stored in SharedPreferences (not secret — shareable).
///   • When signing, the private key is decrypted in-memory, used to produce
///     an RSA-PKCS1v15/SHA-256 signature, then immediately discarded.
///   • The base64 signature string is embedded in the Prescription model and
///     rendered as a QR code in the PDF for easy verification.
///
/// TODO(auth-team): Replace the password passed into [signData] / [validatePassword]
/// with the actual user credential from your authentication session once login
/// is implemented. The crypto storage and signing logic stays the same.
class CryptoService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _encryptedPrivKeyKey = 'medecos_doctor_priv_key_enc';
  static const String _publicKeyPrefKey = 'medecos_doctor_pub_key';
  static const String _keyGenFlagKey = 'medecos_doctor_keys_ready';

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns true if an RSA key pair has already been generated on this device.
  static Future<bool> hasKeyPair() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGenFlagKey) ?? false;
  }

  /// Returns the doctor's RSA public key as a JSON string (safe to share).
  static Future<String?> getPublicKeyJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_publicKeyPrefKey);
  }

  /// One-time setup: generates RSA-2048 key pair and stores it securely.
  /// The private key is AES-256 encrypted using [password] before storage.
  static Future<void> generateAndStoreKeyPair(String password) async {
    // Run CPU-heavy key generation and encryption in a background isolate
    final result = await compute(_generateAndEncryptKeysIsolate, password);

    await _storage.write(key: _encryptedPrivKeyKey, value: result['encryptedPriv']!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_publicKeyPrefKey, result['pubJson']!);
    await prefs.setBool(_keyGenFlagKey, true);
  }

  static Future<Map<String, String>> _generateAndEncryptKeysIsolate(String password) async {
    // RSA-2048 key generation (~2-4 seconds)
    final pair = _generateRSAKeyPair();
    final pub = pair.publicKey as RSAPublicKey;
    final priv = pair.privateKey as RSAPrivateKey;

    // Serialize keys to JSON strings (BigInt → decimal string)
    final pubJson = jsonEncode({
      'n': pub.modulus!.toString(),
      'e': pub.exponent!.toString(),
    });
    final privJson = jsonEncode({
      'n': priv.modulus!.toString(),
      'e': priv.publicExponent!.toString(),
      'd': priv.privateExponent!.toString(),
      'p': priv.p!.toString(),
      'q': priv.q!.toString(),
    });

    // Encrypt private key with password before storing
    final encryptedPriv = _encryptWithPassword(privJson, password);
    return {'pubJson': pubJson, 'encryptedPriv': encryptedPriv};
  }

  /// Validates [password] by attempting to decrypt the stored private key.
  /// Returns true if correct, false if wrong password.
  static Future<bool> validatePassword(String password) async {
    try {
      final enc = await _storage.read(key: _encryptedPrivKeyKey);
      if (enc == null) return false;
      _decryptWithPassword(enc, password); // throws FormatException on wrong pw
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Signs [canonicalData] with the doctor's RSA private key.
  /// [password] is used to decrypt the private key from secure storage.
  ///
  /// Returns a base64-encoded RSA-PKCS1v15/SHA-256 signature.
  /// Throws [FormatException] with message "Invalid password" on wrong password.
  static Future<String> signData(String canonicalData, String password) async {
    final enc = await _storage.read(key: _encryptedPrivKeyKey);
    if (enc == null) throw Exception('No private key found — generate keys first.');

    // Run CPU-heavy decryption and signing in a background isolate
    return compute(_decryptAndSignIsolate, {
      'enc': enc,
      'password': password,
      'canonicalData': canonicalData,
    });
  }

  static Future<String> _decryptAndSignIsolate(Map<String, String> args) async {
    final enc = args['enc']!;
    final password = args['password']!;
    final canonicalData = args['canonicalData']!;

    // Decrypt & parse private key
    final privJson = _decryptWithPassword(enc, password);
    final privateKey = _privFromJson(privJson);

    // RSA-PKCS1v15 / SHA-256 signature
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final sig = signer.generateSignature(
      Uint8List.fromList(utf8.encode(canonicalData)),
    );

    return base64Encode(sig.bytes);
  }

  /// Verifies that [signatureBase64] is a valid RSA signature of [canonicalData]
  /// produced by the private key corresponding to [publicKeyJson].
  static bool verifySignature(
    String canonicalData,
    String signatureBase64,
    String publicKeyJson,
  ) {
    try {
      final publicKey = _pubFromJson(publicKeyJson);
      final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
      verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
      return verifier.verifySignature(
        Uint8List.fromList(utf8.encode(canonicalData)),
        RSASignature(base64Decode(signatureBase64)),
      );
    } catch (_) {
      return false;
    }
  }

  /// Builds the canonical string that is signed/verified.
  /// All critical prescription fields are included, pipe-delimited.
  /// This string is deterministic: same data always produces the same string.
  static String buildCanonicalString({
    required String prescriptionId,
    required String patientId,
    required String patientName,
    required String doctorName,
    required String isoDate,
    required String diagnosis,
    required List<Map<String, String>> medicines,
    required List<String> labTests,
  }) {
    return [
      prescriptionId,
      patientId,
      patientName,
      doctorName,
      isoDate,
      diagnosis,
      jsonEncode(medicines),
      jsonEncode(labTests),
    ].join('||');
  }

  // ─── RSA Key Generation ────────────────────────────────────────────────────

  static AsymmetricKeyPair<PublicKey, PrivateKey> _generateRSAKeyPair() {
    final keyGen = RSAKeyGenerator();
    final rng = _buildSecureRandom();
    keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
      rng,
    ));
    return keyGen.generateKeyPair();
  }

  static SecureRandom _buildSecureRandom() {
    final rng = Random.secure();
    final seed = Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
    final fortuna = FortunaRandom();
    fortuna.seed(KeyParameter(seed));
    return fortuna;
  }

  // ─── Key Serialization ─────────────────────────────────────────────────────

  static RSAPrivateKey _privFromJson(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return RSAPrivateKey(
      BigInt.parse(m['n'] as String),
      BigInt.parse(m['d'] as String),
      BigInt.parse(m['p'] as String),
      BigInt.parse(m['q'] as String),
    );
  }

  static RSAPublicKey _pubFromJson(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return RSAPublicKey(
      BigInt.parse(m['n'] as String),
      BigInt.parse(m['e'] as String),
    );
  }

  // ─── AES-256-CBC + PBKDF2-HMAC-SHA256 Encryption ─────────────────────────
  // Private key is encrypted before being stored. An HMAC over the ciphertext
  // provides authenticated encryption: wrong password → HMAC mismatch → throws.

  static String _encryptWithPassword(String plaintext, String password) {
    final rng = Random.secure();
    final salt = _randBytes(rng, 16);
    final iv = _randBytes(rng, 16);
    final hmacSalt = _randBytes(rng, 16);

    final aesKey = _deriveKey(password, salt, 32);
    final hmacKey = _deriveKey(password, hmacSalt, 32);

    // AES-256-CBC encrypt
    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(aesKey), iv));
    final padded = _pkcs7Pad(Uint8List.fromList(utf8.encode(plaintext)), 16);
    final ciphertext = Uint8List(padded.length);
    for (var off = 0; off < padded.length; off += 16) {
      cipher.processBlock(padded, off, ciphertext, off);
    }

    // HMAC-SHA256 authenticates ciphertext (detects wrong password cleanly)
    final hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(hmacKey));
    hmac.update(ciphertext, 0, ciphertext.length);
    final mac = Uint8List(hmac.macSize);
    hmac.doFinal(mac, 0);

    return jsonEncode({
      'salt': base64Encode(salt),
      'iv': base64Encode(iv),
      'hmacSalt': base64Encode(hmacSalt),
      'mac': base64Encode(mac),
      'ct': base64Encode(ciphertext),
    });
  }

  static String _decryptWithPassword(String encJson, String password) {
    final m = jsonDecode(encJson) as Map<String, dynamic>;
    final salt = base64Decode(m['salt'] as String);
    final iv = base64Decode(m['iv'] as String);
    final hmacSalt = base64Decode(m['hmacSalt'] as String);
    final storedMac = base64Decode(m['mac'] as String);
    final ciphertext = base64Decode(m['ct'] as String);

    final aesKey = _deriveKey(password, salt, 32);
    final hmacKey = _deriveKey(password, hmacSalt, 32);

    // Verify HMAC before decrypting (constant-time comparison prevents oracle attacks)
    final hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(hmacKey));
    hmac.update(ciphertext, 0, ciphertext.length);
    final computedMac = Uint8List(hmac.macSize);
    hmac.doFinal(computedMac, 0);

    if (!_ctEqual(storedMac, computedMac)) {
      throw const FormatException('Invalid password');
    }

    // AES-256-CBC decrypt
    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(aesKey), iv));
    final decrypted = Uint8List(ciphertext.length);
    for (var off = 0; off < ciphertext.length; off += 16) {
      cipher.processBlock(ciphertext, off, decrypted, off);
    }

    return utf8.decode(_pkcs7Unpad(decrypted));
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static Uint8List _deriveKey(String password, Uint8List salt, int len) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 10000, len));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List _pkcs7Pad(Uint8List data, int blockSize) {
    final pad = blockSize - (data.length % blockSize);
    return Uint8List.fromList([...data, ...List.filled(pad, pad)]);
  }

  static Uint8List _pkcs7Unpad(Uint8List data) =>
      data.sublist(0, data.length - data.last);

  /// Constant-time equality to prevent timing-based HMAC oracle attacks.
  static bool _ctEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static Uint8List _randBytes(Random rng, int n) =>
      Uint8List.fromList(List.generate(n, (_) => rng.nextInt(256)));
}
