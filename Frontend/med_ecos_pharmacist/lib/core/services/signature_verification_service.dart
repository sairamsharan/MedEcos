import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Read-only RSA signature verification service.
///
/// The pharmacist app never generates keys or signs data — it only
/// verifies signatures that were created by the doctor app.
class SignatureVerificationService {
  /// Verifies that [signatureBase64] is a valid RSA signature of
  /// [canonicalData] produced by the private key corresponding to
  /// [publicKeyJson].
  static bool verifySignature(
    String canonicalData,
    String signatureBase64,
    String publicKeyJson,
  ) {
    try {
      final m = jsonDecode(publicKeyJson) as Map<String, dynamic>;
      final publicKey = RSAPublicKey(
        BigInt.parse(m['n'] as String),
        BigInt.parse(m['e'] as String),
      );

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

  /// Builds the same canonical string the doctor app uses when signing.
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
}
