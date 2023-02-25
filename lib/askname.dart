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
        body: AskNameForm(),
      ),
    );
  }
}


class AskNameForm extends StatelessWidget {
  final userNameController = TextEditingController();

  AskNameForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:  <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: TextField(
            controller: userNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your name',
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: ElevatedButton(
              child: const Text("Continue"),
              onPressed: () {
                Navigator.push((context), MaterialPageRoute(
                  builder: (context) =>  MyApp(nameOfUser: userNameController.text,)
                ));
              },
            )
          ),
        ),
      ],
    );
  }
}