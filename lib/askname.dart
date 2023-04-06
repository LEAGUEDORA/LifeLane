import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:frontned/initializer.dart';
import 'package:frontned/mymap.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AskName extends StatelessWidget {

  const AskName({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appTitle = "Ambulance For Help";
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        body: const AskNameFormStateFulWidget(),
      ),
    );
  }
}

class AskNameFormStateFulWidget extends StatefulWidget {
  const AskNameFormStateFulWidget({super.key});


  @override
  State<AskNameFormStateFulWidget> createState() => _AsknameFormState();
}

enum Role {police, driver, user}

class _AsknameFormState extends State<AskNameFormStateFulWidget> {
  Role _role = Role.user;
  final userNameController = TextEditingController();



  void redirectToMaps() async {

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('name') != null){
      Navigator.push((context), MaterialPageRoute(
          builder: (context) =>  MyApp(nameOfUser: prefs.getString('name')!, roleOfUser: prefs.getString('role')!)
      ));
    }
    // return false;

  }

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    print(initialMessage);
    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    print("Handling Message");
    print(message.data.toString());
    if (message.data.containsKey("id")) {
      var id = message.data['id'];

      Navigator.push((context), MaterialPageRoute(
          builder: (context) =>  MyMap(id))
      );
    }
    return;
  }

@override
  void initState() {
    // final SharedPreferences prefs = await SharedPreferences.getInstance();
    // if (prefs.getString('name') != null){
    //   Navigator.push((context), MaterialPageRoute(
    //       builder: (context) =>  MyApp(nameOfUser: prefs.getString('name')!, roleOfUser: prefs.getString('role')!)
    //   ));
    //   return;
    // }
  super.initState();
  setupInteractedMessage();
  redirectToMaps();


  }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:  <Widget>[
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
                Navigator.push((context), MaterialPageRoute(
                  builder: (context) =>  MyApp(nameOfUser: userNameController.text, roleOfUser: _role.name)
                ));

              },
            )
          ),
        ),
      ],
    );
  }


}