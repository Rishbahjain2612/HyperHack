import 'package:flutter/material.dart';

/// A reusable app bar widget.
PreferredSizeWidget buildAppBar({required String title}) {
  return AppBar(
    title: Text(title),
    centerTitle: true,
    backgroundColor: Colors.blue,
  );
}