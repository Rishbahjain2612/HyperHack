import 'package:flutter/material.dart';

class PayloadDisplay extends StatelessWidget {
  final String payload;

  const PayloadDisplay({Key? key, required this.payload}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        payload,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
