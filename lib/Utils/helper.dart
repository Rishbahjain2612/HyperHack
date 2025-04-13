import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'generate_signature.dart';

/// Generate a unique ID starting with YJP of 35 chars
String generateYJPString() {
  const prefix = 'YJP';
  final uuid = const Uuid().v4().replaceAll('-', '').substring(0, 32);
  return '$prefix${uuid.substring(0, 32)}';
}

/// Load private key (if needed elsewhere)
Future<String> loadPrivateKey() async {
  return await rootBundle.loadString('assets/keys/private-key.pem');
}

/// Build initiate payload
Future<Map<String, dynamic>> buildInitPayload() async {
  const clientId = "testhyperupi";
  const environment = "sandbox";
  const logLevel = 1;

  final signaturePayload = {
    "merchantCustomerId": "abcde",
    "timestamp": (DateTime.now().millisecondsSinceEpoch).toString(),
    "merchantId": "HYPERUPITEST",
    "merchantChannelId": "HYPERUPITESTAPP",
  };

  final base64Values = await PayloadSigner.getSignedContent(signaturePayload);
  final protected = jsonDecode(base64Values)['protected'];
  final signature = jsonDecode(base64Values)['signature'];
  final signaturePayloadNew = jsonDecode(base64Values)['signaturePayload'];

  return {
    "issuingPsp": "YES_BIZ",
    "enableJwsAuth": true,
    "action": "initiate",
    "clientId": clientId,
    "merchantLoader": false,
    "protected": protected,
    "signature": signature,
    "signaturePayload": signaturePayloadNew,
    "environment": environment,
    "logLevel": logLevel
  };
}

/// Build process payload
Future<Map<String, dynamic>> buildProcessPayload(String action, String? intentData) async {

  const customerMobileNumber = "917017946155";
  String merchantRequestId = generateYJPString();

  Map<String, dynamic> signaturePayload = {
    "merchantCustomerId": "abcde",
    "timestamp": (DateTime.now().millisecondsSinceEpoch).toString(),
    "merchantId": "HYPERUPITEST",
    "merchantChannelId": "HYPERUPITESTAPP"
  };

  Map<String, dynamic> processPayload = {
    "action": action,
    "customerMobileNumber": customerMobileNumber,
    "showStatusScreen": true,
    "udfParameters": "{}"
  };

  switch (action){
    case "onboardingAndPay":
      signaturePayload = signaturePayload ..addAll({
        "amount": "50.00",
        "merchantVpa": "hyperupitest@ypay",
        "merchantRequestId": merchantRequestId
      });
      break;
    case "management":
      break;
    case "incomingIntent":
      if (intentData != null) {
        processPayload = processPayload ..addAll({
          "intentData": intentData,
        });
      } else {
        throw Exception("Intent data is null");
      }
      break;
    default:
      throw Exception("Invalid action");
  }

  final base64Values = await PayloadSigner.getSignedContent(signaturePayload);
  final protected = jsonDecode(base64Values)['protected'];
  final signature = jsonDecode(base64Values)['signature'];
  final signaturePayloadNew = jsonDecode(base64Values)['signaturePayload'];


  return processPayload ..addAll({
    "protected": protected,
    "signature": signature,
    "signaturePayload": signaturePayloadNew
  });
}

Future<Map<String, dynamic>> buildPayload(int payloadType, String? intentData) async {
  final requestId = const Uuid().v4();
  const service = "in.juspay.hyperapi";

  Map<String, dynamic> payload; // Declare the payload as Map<String, dynamic> instead of Future<Map<String, dynamic>>.

  switch (payloadType) {
    case 0:
      payload = await buildInitPayload(); // Await the result of buildInitPayload.
      break;
    case 1:
      payload = await buildProcessPayload("onboardingAndPay", null); // Await the result of buildProcessPayload.
      break;
    case 2:
      payload = await buildProcessPayload("management", null); // Await the result of buildProcessPayload.
      break;
    case 3:
      payload = await buildProcessPayload("incomingIntent", intentData);
      break;
    default:
      throw Exception("Invalid payload type");
  }

  // Return the final map with the payload.
  return {
    "requestId": requestId,
    "service": service,
    "payload": payload
  };
}
