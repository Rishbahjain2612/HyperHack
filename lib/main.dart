import 'package:flutter/material.dart';
import 'package:flutterproj/screens/home.dart';
import 'package:hypersdkflutter/hypersdkflutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SDK Integration',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(hyperSDK: HyperSDK()),
    );
  }
}
