// Package by @Bala534

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:frontned/initializer.dart';
import 'package:frontned/mymap.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AskName extends StatelessWidget {
  const AskName({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appTitle =
        "Ambulance For Help"; // Constant name for the app bar title
    return MaterialApp(
      // Material is a widget containing the containers related to title, Appbar, bottom bar
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        body:
            const AskNameFormStateFulWidget(), // The rest of the body is dedicated to ask name and user type from the user
      ),
    );
  }
}

class AskNameFormStateFulWidget extends StatefulWidget {
  // Stateful widget which doesn't accept anything as inputs
  const AskNameFormStateFulWidget({super.key});

  @override
  State<AskNameFormStateFulWidget> createState() => _AsknameFormState();
}

enum Role { police, driver, user } // Enumarator for roles

class _AsknameFormState extends State<AskNameFormStateFulWidget> {
  Role _role = Role.user; // Default user (patient)
  final userNameController =
      TextEditingController(); // Controller for text input field

  void redirectToMaps() async {
    // If the application already contains details of the user like name, and user type the user is redirected to Maps page
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('name') != null) {
      Navigator.push(
          (context),
          MaterialPageRoute(
              builder: (context) => MyApp(
                  nameOfUser: prefs.getString('name')!,
                  roleOfUser: prefs.getString('role')!)));
    }
  }

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // Resource @ https://firebase.flutter.dev/docs/messaging/notifications/
    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp
        .listen(_handleMessage); // Invokes after opening the notification
  }

  void _handleMessage(RemoteMessage message) {
    // message contains {"id": ""} id -> the id of the patient which is further used to open the patient maps
    if (message.data.containsKey("id")) {
      var id = message.data['id'];
      Navigator.push(
          (context),
          MaterialPageRoute(
              builder: (context) =>
                  MyMap(id))); // If ID exists in the message route to next page
    }
    return;
  }

  @override
  void initState() {
    super.initState();
    setupInteractedMessage(); // Check for interacted notifications
    redirectToMaps(); // Redirect to maps if data is available
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // Div in CSS
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: TextField(
            controller: userNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your name',
            ),
          ),
        ),
        Column(
          children: [
            ListTile(
              title: const Text("Patient"),
              leading: Radio<Role>(
                  value: Role.user,
                  groupValue: _role,
                  onChanged: (Role? value) {
                    setState(() {
                      _role = value!;
                    });
                  }),
            ),
            ListTile(
              title: const Text("Police"),
              leading: Radio<Role>(
                  value: Role.police,
                  groupValue: _role,
                  onChanged: (Role? value) {
                    setState(() {
                      _role = value!;
                    });
                  }),
            ),
            ListTile(
              title: const Text("Driver"),
              leading: Radio<Role>(
                  value: Role.driver,
                  groupValue: _role,
                  onChanged: (Role? value) {
                    setState(() {
                      _role = value!;
                    });
                  }),
            ),
          ],
        ),
        Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: ElevatedButton(
                child: const Text("Continue"),
                onPressed: () {
                  Navigator.push(
                      (context),
                      MaterialPageRoute(
                          builder: (context) => MyApp(
                              nameOfUser: userNameController.text,
                              roleOfUser: _role.name)));
                },
              )),
        ),
      ],
    );
  }
}
