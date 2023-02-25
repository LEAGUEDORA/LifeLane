import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frontned/askname.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("Init");
  runApp(
    const MaterialApp(
      home: AskName(),
    )
  );
}



