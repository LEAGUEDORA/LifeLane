// By @19PA1A0562

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frontned/askname.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontned/initializer.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Entry point for Firebase background notifications
  await Firebase.initializeApp();
}

void main() async {
  // Main method where Flutter starts running the application

  WidgetsFlutterBinding
      .ensureInitialized(); // This methods ensures that all the widgets are initialized before displaying them
  await Firebase
      .initializeApp(); // Async function to initialize firebase. This function picks up the `google-services.json` from `android/app/` folder.
  // This file contains the required information to connect with 19pa1a0562@vishnu.edu.in file

  requestNotificationPermission(); // This method pops up the request on the app for asking permission to push notifications.

  final fcmToken = await FirebaseMessaging.instance
      .getToken(); // Written by @19PA1A0562 to get a firebase unique notification ID
  final SharedPreferences prefs = await SharedPreferences
      .getInstance(); // Shared Preference library which acts as a local storage to store Token
  prefs.setString(
      'token', fcmToken.toString()); // Setting the token into local storage

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler); // Background message handler. Works when the app is in background

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Written by @19pa1a0562 to listen to the remote messages to do some content
  });

  runApp(const MaterialApp(
    home:
        AskName(), // Default screen is Ask Name regardless of the user written by @19PA1A0562
  ));
}
