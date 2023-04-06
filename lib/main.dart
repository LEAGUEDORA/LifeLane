import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frontned/askname.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontned/initializer.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';


void requestNotificationPermission() async{
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  await Firebase.initializeApp();
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  requestNotificationPermission();
  final fcmToken =  await FirebaseMessaging.instance.getToken();
  print(fcmToken);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('token', fcmToken.toString());
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });


  runApp(
      const MaterialApp(
        home: AskName(),
      )
  );
}



