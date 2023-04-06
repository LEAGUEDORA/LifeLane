// By @19PA1A0548

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:frontned/mymap.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MyApp extends StatefulWidget {
  // List view of patients in this widget
  String nameOfUser; // Name of the user
  String roleOfUser; // Role of the user
  MyApp({Key? key, required this.nameOfUser, required this.roleOfUser})
      : super(key: key); // Params are name of the user and role of the user

  @override
  _MyAppState createState() =>
      _MyAppState(nameOfUser: nameOfUser, roleOfUser: roleOfUser);
}

class _MyAppState extends State<MyApp> {
  String nameOfUser;
  String roleOfUser;
  String partDriver = "";
  _MyAppState({required this.nameOfUser, required this.roleOfUser});

  final loc.Location location = loc.Location(); // Location tracker service
  StreamSubscription<loc.LocationData>?
      _locationSubscription; // Location tracker listening service

  void updateDatabase() async {
    // Saves the Firebase generated notification token to the database for further use
    final SharedPreferences prefs = await SharedPreferences
        .getInstance(); // Get the instance of local storage
    var dburl = Uri.https(
        'ambulance-api-eight.vercel.app', "saveuser"); // Api call to database
    var responsedriver = await http.post(dburl, body: {
      "name": nameOfUser,
      "role": roleOfUser,
      "token": prefs.getString('token')
    });
  }

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp
        .listen(_handleMessage); //Invokes after opening the application
  }

  void _handleMessage(RemoteMessage message) {
    // message {"id": ""} id referes to the name of the patient in the screen
    if (message.data.containsKey("id")) {
      // If the ID exists the user will be redirected to the maps page
      var id = message.data['id'];
      Navigator.push(
          (context), MaterialPageRoute(builder: (context) => MyMap(id)));
    }
  }

  @override
  void initState() {
    setValues(nameOfUser, roleOfUser);
    updateDatabase(); // Updates the database with firebase token
    super.initState();
    _requestPermission(); // Request permission for location services
    setupInteractedMessage(); // Interactive messages for notifications
    location.changeSettings(
        interval: 30,
        accuracy: loc.LocationAccuracy
            .high); // SetInterval for every 30ms to reload the map
    location.enableBackgroundMode(
        enable: true); // asking the user to give background notification access

    final Future<loc.LocationData> _locationResult =
        location.getLocation(); // Getting current location
    _locationResult.then((value) => {
          FirebaseFirestore.instance.collection('location').doc(nameOfUser).set(
              {
                "name": nameOfUser,
                "role": roleOfUser,
                "latitude": value.latitude,
                "longitude": value.longitude,
                "driver": ""
              },
              SetOptions(
                  merge:
                      true)) // Insert the user data into firebase for location tracking
        });
  }

  void setValues(name, role) async {
    // Save data into local storage for further use
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("name", nameOfUser);
    prefs.setString("role", roleOfUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Ambulance"),
      ),
      body: Column(
        children: [
          TextButton(
              onPressed: () {
                _getLocation(nameOfUser, roleOfUser); // Current location
                _listenLocation(nameOfUser,
                    roleOfUser); // Listen constantly to location service to get updates on the user location
              },
              child: const Text("Call for Ambulance")),
          Column(
            children: const [
              Text(
                "Check your ambulance status",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              )
            ],
          ),
          Expanded(
              child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('location')
                .snapshots(), //Get all current users in firebase
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                // If there is no data
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                  // If there is data
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, index) {
                    if ((snapshot.data!.docs[index]['driver'] != "") &&
                        (snapshot.data!.docs[index]['role'] != "police")) {
                      return ListTile(
                        title: Text(snapshot.data!.docs[index]['name']
                            .toString()), // Name of the patient
                        subtitle: Row(
                          children: [
                            Text(snapshot
                                .data!.docs[index]['latitude'] // Latitude
                                .toString()),
                            const SizedBox(
                              width: 20,
                            ),
                            Text(snapshot
                                .data!.docs[index]['longitude'] // Longitude
                                .toString()),
                          ],
                        ),
                        trailing: IconButton(
                          // Navigation page
                          icon: const Icon(Icons.directions),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    MyMap(snapshot.data!.docs[index].id)));
                          },
                        ),
                      );
                    } else {
                      return Text("");
                    }
                  });
            },
          ))
        ],
      ),
    );
  }


  Future<List> searchForNearestAmbulance  (
      // This algorithm finds the nearest ambulance for the user
      loc.LocationData currentLocation,
      String nameOfUser) async {
    double maximum = double.maxFinite;
    String name = "";
    String patient = "";

    FirebaseFirestore.instance
        .collection('location')
        .snapshots()
        .forEach((element) {
      var data = element.docs;
      for (var new_element in data) {
        var data = new_element.data();
        if (data['role'] == "driver" && data['driver'] == "") {
          double distanceInMeters = Geolocator.distanceBetween(
              currentLocation.latitude!,
              currentLocation.longitude!,
              data['latitude'],
              data['longitude']);
          if (distanceInMeters / 1000 < maximum && nameOfUser != data['name']) {
            maximum = distanceInMeters;
            name = data['name'];
            insertDriverForDocument(nameOfUser,
                name); // Assigns the nearest driver to the patient in the firebase

          }
        }
      }

    });
    print(name);
    // Send notification to driver
    // var urldriver = Uri.https('ambulance-api-eight.vercel.app', "alertdriver");
    // var responsedriver = await http.post(urldriver, body: {
    //   "title": " Alert ⚠️" + nameOfUser + " is waiting for you",
    //   'body': "Pick up " + nameOfUser + ". He is in emergency",
    //   "name": name,
    //   "id": nameOfUser
    // });
    // Send notifications to patient
    var urlpatient =
        Uri.https('ambulance-api-eight.vercel.app', "alertpatient");
    var responsepatient = await http.post(urlpatient, body: {
      "title": " Rescue is on the way ⚡ ",
      'body': name + " is on the way to pick up you.",
      "name": nameOfUser,
      "id": nameOfUser
    });

    // Send notifications to police
    var url = Uri.https('ambulance-api-eight.vercel.app', "alertpolice");
    var response = await http
        .post(url, body: {"title": "Ambulance Alert ⚠️", "body": "Clear traffic 🚥🚦🚸⛔", "id": nameOfUser});
    return [maximum, name];
  }

  void insertDriverForDocument(String nameOfUser, String nameOfDriver) async {
    // Insersts the name of driver in patient document
    await FirebaseFirestore.instance
        .collection('location')
        .doc(nameOfUser)
        .update({"driver": nameOfDriver});
  }

  _getLocation(String nameOfUser, String roleOfUser) async {
    // Get & set the current location in firebase
    try {
      final loc.LocationData _locationResult = await location.getLocation();
      var returedData = searchForNearestAmbulance(_locationResult, nameOfUser);
      await FirebaseFirestore.instance
          .collection('location')
          .doc(nameOfUser)
          .set({
        'latitude': _locationResult.latitude,
        'longitude': _locationResult.longitude,
        'name': nameOfUser,
        'role': roleOfUser
      }, SetOptions(merge: true));

    } catch (e) {
      print(e);
    }

  }

  Future<void> _listenLocation(String nameOfUser, String roleOfUser) async {
    // Listen to updates of the location
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentLocation) async {
      await FirebaseFirestore.instance
          .collection('location')
          .doc(nameOfUser)
          .set({
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
        'name': nameOfUser,
      }, SetOptions(merge: true));
    });
  }

  _stopListening() {
    // Deprecated not using. But this will stop listening to location changes
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  _requestPermission() async {
    // Request access to location
    var status = await Permission.location.request();
    if (status.isGranted) {
      print("Location Status Granted");
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}
