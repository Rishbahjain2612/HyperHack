import 'package:flutter/material.dart';
import 'payload_display.dart';

class HomeBody extends StatelessWidget {
  final bool showLoader;
  final int countProductOne;
  final int countProductTwo;
  final VoidCallback onGetPayload;
  final VoidCallback onCallProcess;
  final String payload;

  const HomeBody({
    Key? key,
    required this.showLoader,
    required this.countProductOne,
    required this.countProductTwo,
    required this.onGetPayload,
    required this.onCallProcess,
    required this.payload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: showLoader
          ? const CircularProgressIndicator()
          : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Product 1 Count: $countProductOne'),
                  Text('Product 2 Count: $countProductTwo'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onGetPayload,
                    child: const Text('Get Process Payload'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onCallProcess,
                    child: const Text('Call Process'),
                  ),
                  const SizedBox(height: 20),
                  PayloadDisplay(payload: payload),
                ],
              ),
            ),
    );
  }
}
