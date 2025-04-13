import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterproj/Utils/handle_intent.dart';
import 'package:hypersdkflutter/hypersdkflutter.dart';
import 'package:logging/logging.dart';
import '../Utils/helper.dart';
import '../widgets/bottom_button.dart';
import '../widgets/app_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum LoaderType { none, initiate, process }

class HomeScreen extends StatefulWidget {
  final HyperSDK hyperSDK;

  const HomeScreen({super.key, required this.hyperSDK});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  LoaderType loaderType = LoaderType.process;
  bool isSdkInitialized = true;
  String payload = "";
  bool isIntentCalled = false;
  bool isPhoneValid = false;

  final log = Logger('HomeScreen');
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String phoneNumber = "";

  @override
  void initState() {
    super.initState();
    initiateHyperSDK();
    intentHandling();
    setupLogging();

    phoneController.addListener(() {
      final valid = RegExp(r'^91\d{10}$').hasMatch(phoneController.text);
      setState(() => isPhoneValid = valid);
    });
  }

  bool get showLoader => loaderType != LoaderType.none;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WillPopScope(
          onWillPop: _handleBackPress,
          child: Scaffold(
            appBar: buildAppBar(title: 'HyperSDK Integration'),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildPhoneInput(),
                      const SizedBox(height: 30),
                      ...buildBottomButtons(),
                      const SizedBox(height: 30),
                      if (payload.isNotEmpty) buildPayloadDisplay(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showLoader)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Phone Number (must start with 91)',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '91XXXXXXXXXX',
            counterText: '',
          ),
          maxLength: 12,
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Phone number is required';
            if (!RegExp(r'^91\d{10}$').hasMatch(value)) {
              return 'Enter valid 12-digit phone number starting with 91';
            }
            return null;
          },
        ),
      ],
    );
  }

  List<Widget> buildBottomButtons() {
    return [
      BottomButton(
        label: 'Call OnboardingAndPay',
        onPressed: isPhoneValid ? () => handleProcessAction(1) : null,
      ),
      const SizedBox(height: 20),
      BottomButton(
        label: 'Call Management',
        onPressed: isPhoneValid ? () => handleProcessAction(2) : null,
      ),
      const SizedBox(height: 20),
      BottomButton(
        label: isSdkInitialized ? 'Terminate' : 'Initiate',
        onPressed:
            isPhoneValid
                ? () => isSdkInitialized ? callTerminate() : initiateHyperSDK()
                : null,
      ),
    ];
  }

  Widget buildPayloadDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SelectableText(
          payload,
          style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  Future<bool> _handleBackPress() async {
    setState(() => loaderType = LoaderType.initiate);
    if (Platform.isAndroid) {
      var result = await widget.hyperSDK.onBackPress();
      setState(() => loaderType = LoaderType.none);
      return result.toLowerCase() != "true";
    }
    return true;
  }

  void handleProcessAction(int action) {
    if (_formKey.currentState?.validate() ?? false) {
      phoneNumber = phoneController.text;
      callProcess(action, null);
    }
  }

  void showToast(String message, Color color) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: color,
      fontSize: 16.0,
    );
  }

  void setupLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  void initiateHyperSDK() async {
    setState(() {
      loaderType = LoaderType.initiate;
      isSdkInitialized = true;
    });
    if (!await widget.hyperSDK.isInitialised()) {
      final payload = await buildPayload(0, null, phoneNumber);
      log.info("Initiate payload: $payload");
      await widget.hyperSDK.initiate(payload, hyperSDKCallbackHandler);
    }
  }

  void callProcess(int action, String? intentData) async {
    setState(() => loaderType = LoaderType.process);
    if (await widget.hyperSDK.isInitialised()) {
      final processPayload = await buildPayload(
        action,
        intentData,
        phoneNumber,
      );
      await widget.hyperSDK.process(processPayload, hyperSDKCallbackHandler);
      log.info("Process called with payload: $processPayload");
    } else {
      setState(() => loaderType = LoaderType.none);
      showToast("SDK is not initialized", Colors.white);
    }
  }

  void callTerminate() async {
    if (await widget.hyperSDK.isInitialised()) {
      await widget.hyperSDK.terminate();
      setState(() => isSdkInitialized = false);
      log.info("HyperSDK terminated");
    } else {
      showToast("SDK is not initialized", Colors.red);
    }
  }

  void intentHandling() async {
    setState(() => loaderType = LoaderType.process);
    var link = await initDeepLinkHandling();
    if (link != null) {
      isIntentCalled = true;
      callProcess(3, link);
      return;
    }
    setState(() => loaderType = LoaderType.none);
  }

  void hyperSDKCallbackHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case "initiate_result":
      case "process_result":
        _handleSdkResult(methodCall);
        break;
      default:
        log.warning("Unhandled method: ${methodCall.method}");
    }
  }

  void _handleSdkResult(MethodCall methodCall) async {
    try {
      final args = json.decode(methodCall.arguments);
      final formatted = const JsonEncoder.withIndent('  ').convert(args);
      log.info("${methodCall.method}: $args");

      if (methodCall.method == "process_result") {
        final action = args['payload']['action'];
        final payload = args['payload'];
        final success =
            (payload['gatewayResponseCode'] == "00" &&
                payload['gatewayResponseMessage'] ==
                    "Your transaction is successful") ||
            (action == "management");

        if (isIntentCalled) {
          await sendResultBackToCaller(
            json.encode({
              'status': success ? 'success' : 'failure',
              'txnId': payload['gatewayTransactionId'],
              'message':
                  success ? 'Transaction completed' : 'Transaction failed',
            }),
          );
        }

        Fluttertoast.showToast(
          msg:
              success
                  ? action == "management"
                      ? "Oye Balle Balle"
                      : "Transaction Successful"
                  : "Transaction Failed/Pending",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: success ? Colors.green : Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }

      setState(() {
        payload = formatted;
        loaderType = LoaderType.none;
      });
    } catch (e) {
      log.severe(
        "Error decoding ${methodCall.method}: $e",
        e,
        StackTrace.current,
      );
      setState(() => loaderType = LoaderType.none);
    }
  }

  Future<void> sendResultBackToCaller(String response) async {
    const platform = MethodChannel('com.rishabh.flutterproj/intent');
    try {
      await platform.invokeMethod('sendResultBack', {'response': response});
    } on PlatformException catch (e) {
      print("Failed to send result: ${e.message}");
    }
  }
}
