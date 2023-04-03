import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frontned/initializer.dart';

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