import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:basic_utils/basic_utils.dart';
/// Utility class for signing JWT payloads using RS256 algorithm
class DartJWS {
  final String kid;
  final String privateKeyPem;

  DartJWS({
    required this.kid,
    required this.privateKeyPem,
  });

  String _base64UrlEncode(Uint8List input) =>
      base64Url.encode(input).replaceAll('=', '');

  Map<String, String> signPayload(Map<String, dynamic> content) {
    final header = {
      'alg': 'RS256',
      'kid': kid,
    };

    final encodedHeader = _base64UrlEncode(utf8.encode(json.encode(header)));
    final encodedPayload = _base64UrlEncode(utf8.encode(json.encode(content)));

    final signingInput = '$encodedHeader.$encodedPayload';

    final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);

    final signer = Signer('SHA-256/RSA');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final signature = signer.generateSignature(utf8.encode(signingInput)) as RSASignature;
    final encodedSignature = _base64UrlEncode(signature.bytes);

    return {
      'protected': encodedHeader,
      'signaturePayload': encodedPayload,
      'signature': encodedSignature,
    };
  }

}
/// Wrapper to sign content
class PayloadSigner {
  static const String _kid = '39e9c9e1-b9d4-3674-77cc-38c97ecd794b';

  static Future<String> _loadPrivateKeyFromAssets() async {
    return await rootBundle.loadString('assets/keys/private-key.pem');
  }

  static Future<String> getSignedContent(Map<String, dynamic> content) async {
    final privateKeyPem = await _loadPrivateKeyFromAssets();
    final signer = DartJWS(kid: _kid, privateKeyPem: privateKeyPem);
    final signedParts = signer.signPayload(content);
    return jsonEncode(signedParts);
  }
}
