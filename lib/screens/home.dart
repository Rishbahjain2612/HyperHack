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

  final log = Logger('HomeScreen');

  @override
  void initState() {
    super.initState();
    initiateHyperSDK();
    intentHandling();
    setupLogging();
  }

  bool get showLoader => loaderType != LoaderType.none;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WillPopScope(
          onWillPop: () async {
            setState(() => loaderType = LoaderType.initiate);
            if (Platform.isAndroid) {
              var backpressResult = await widget.hyperSDK.onBackPress();
              setState(() => loaderType = LoaderType.none);
              return backpressResult.toLowerCase() != "true";
            }
            return true;
          },
          child: Scaffold(
            appBar: buildAppBar(title: 'HyperSDK Integration'),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BottomButton(
                      label: 'Call OnboardingAndPay',
                      onPressed: () => callProcess(1, null),
                    ),
                    const SizedBox(height: 20),
                    BottomButton(
                      label: 'Call Management',
                      onPressed: () => callProcess(2, null),
                    ),
                    const SizedBox(height: 20),
                    BottomButton(
                      label: isSdkInitialized ? 'Terminate' : 'Initiate',
                      onPressed: () => isSdkInitialized ? callTerminate() : initiateHyperSDK(),
                    ),
                    const SizedBox(height: 30),
                    if (payload.isNotEmpty)
                      Container(
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showLoader)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
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
      final initiatePayload = await buildPayload(0, null);
      log.info("Initiate payload: $initiatePayload");
      await widget.hyperSDK.initiate(initiatePayload, hyperSDKCallbackHandler);
    }
  }

  void callProcess(int action, String? intentData) async {
    setState(() => loaderType = LoaderType.process);
    if (await widget.hyperSDK.isInitialised()) {
      final processPayload = await buildPayload(action, intentData);
      await widget.hyperSDK.process(processPayload, hyperSDKCallbackHandler);
      log.info("Process called with payload: $processPayload");
    } else {
      setState(() => loaderType = LoaderType.none);
      Fluttertoast.showToast(
        msg: "SDK is not initialized",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void callTerminate() async {
    if (await widget.hyperSDK.isInitialised()) {
      await widget.hyperSDK.terminate();
      setState(() => isSdkInitialized = false);
      log.info("HyperSDK terminated");
    } else {
      Fluttertoast.showToast(
        msg: "SDK is not initialized",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void hyperSDKCallbackHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case "initiate_result":
        try {
          final args = json.decode(methodCall.arguments);
          log.info("Initiate result: $args");
          setState(() {
            payload = const JsonEncoder.withIndent('  ').convert(args);
            loaderType = LoaderType.none;
          });
        } catch (e) {
          log.severe("Error decoding process_result: $e", e, StackTrace.current);
          setState(() => loaderType = LoaderType.none);
        }
        break;

      case "process_result":
        try {
          final args = json.decode(methodCall.arguments);
          log.info("Process result: $args");
          if (args['payload']['gatewayResponseCode'] == "00" && args['payload']['gatewayResponseMessage'] == "Your transaction is successful") {
            await sendResultBackToCaller(json.encode({
                'status': 'success',
                'txnId': args['payload']['gatewayTransactionId'],
                'message': 'Transaction completed',
              }));
          } else {
            await sendResultBackToCaller(json.encode({
                'status': 'failure',
                'txnId': args['payload']['gatewayTransactionId'],
                'message': 'Transaction failed',
              }));
          }
          setState(() {
            payload = const JsonEncoder.withIndent('  ').convert(args);
            if (args['payload']['gatewayResponseCode'] == "00" && args['payload']['gatewayResponseMessage'] == "Your transaction is successful") {
              Fluttertoast.showToast(
                msg: "Transaction Successful",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.green,
                textColor: Colors.white,
                fontSize: 16.0,
              );

            } else {
              Fluttertoast.showToast(
                msg: "Transaction Failed/Pending",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                fontSize: 16.0,
              );

            }
            loaderType = LoaderType.none;
          });
        } catch (e) {
          log.severe("Error decoding process_result: $e", e, StackTrace.current);
          setState(() => loaderType = LoaderType.none);
        }
        break;

      default:
        log.warning("Unhandled method: ${methodCall.method}");
        break;
    }
  }

  void intentHandling() async {
    setState(() => loaderType = LoaderType.process);
    var initialLink = await initDeepLinkHandling();
    if (initialLink != null) {
      callProcess(3, initialLink);
      return;
    }
    setState(() => loaderType = LoaderType.none);
  }
  Future<void> sendResultBackToCaller(String response) async {
    const platform = MethodChannel('com.rishabh.flutterproj/intent');
    try {
      await platform.invokeMethod('sendResultBack', {
        'response': response,
      });
    } on PlatformException catch (e) {
      print("Failed to send result: ${e.message}");
    }
  }

}
