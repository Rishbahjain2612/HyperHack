// lib/widgets/bottom_button.dart
import 'package:flutter/material.dart';

class BottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const BottomButton({Key? key, required this.label, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        textStyle: TextStyle(fontSize: 18),
      ),
    );
  }
}
