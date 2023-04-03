
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frontned/mymap.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class MyApp extends StatefulWidget {
  String nameOfUser;
  String roleOfUser;
  MyApp({Key? key, required this.nameOfUser, required this.roleOfUser}): super(key: key);

  @override
  _MyAppState createState() => _MyAppState(nameOfUser: nameOfUser, roleOfUser: roleOfUser);
}

class _MyAppState extends State<MyApp> {
  String nameOfUser;
  String roleOfUser;
  _MyAppState({required this.nameOfUser, required this.roleOfUser});


  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  @override
  void initState()  {
    super.initState();
    _requestPermission();
    location.changeSettings(interval: 30, accuracy: loc.LocationAccuracy.high);
    location.enableBackgroundMode(enable: true);
    final Future<loc.LocationData> _locationResult =  location.getLocation();
    _locationResult.then((value) =>
        {
          FirebaseFirestore.instance.collection('location').doc(nameOfUser).set(
          {
          "name": nameOfUser,
          "role": roleOfUser,
          "latitude": value.latitude,
          "longitude": value.longitude,
            "driver": ""
          }, SetOptions(merge: true))
        }
    );

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Ambulance"),
      ),
      body: Column(
        children: [
          TextButton(onPressed: () {
            _getLocation(nameOfUser, roleOfUser);
            _listenLocation(nameOfUser, roleOfUser);
          }, child: const Text("Call for Ambulance")),
          Column(
            children:  const [
              Text("Check your ambulance status",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20
              ),)
            ],
          ),
          Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('location')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }


                  return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      itemBuilder: (context, index) {
                        if ((snapshot.data!.docs[index]['driver'] != "") && (snapshot.data!.docs[index]['role'] != "police") ){
                          return ListTile(
                            title: Text(snapshot.data!.docs[index]['name']
                                .toString()),
                            subtitle: Row(
                              children: [
                                Text(snapshot.data!.docs[index]['latitude']
                                    .toString()),
                                const SizedBox(
                                  width: 20,
                                ),
                                Text(snapshot.data!.docs[index]['longitude']
                                    .toString()),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.directions),
                              onPressed: () {
                                Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) =>
                                        MyMap(snapshot.data!.docs[index].id))
                                );
                              },
                            ),
                          );
                        }
                        else {
                          return Text("");
                        }
                      });
                },))
        ],
      ),
    );
  }

  Future<List> searchForNearestAmbulance(loc.LocationData currentLocation, String nameOfUser) async {
    double maximum = double.maxFinite;
    String name = "";
    FirebaseFirestore.instance.collection('location').snapshots().forEach((element) {
      var data = element.docs;
      for (var new_element in data) {
        var data = new_element.data();
        if (data['role'] == "driver"){
          double distanceInMeters = Geolocator.distanceBetween(currentLocation.latitude!, currentLocation.longitude!, data['latitude'], data['longitude']);
          if (distanceInMeters/1000 < maximum && nameOfUser != data['name']) {
            maximum = distanceInMeters;
            name = data['name'];
            insertDriverForDocument(nameOfUser, name);
          }
        }
      }
    });
    return [maximum, name];

  }

  void insertDriverForDocument(String nameOfUser, String nameOfDriver) async {
    await FirebaseFirestore.instance.collection('location').doc(nameOfUser).update({
      "driver": nameOfDriver
    });

  }

  _getLocation(String nameOfUser, String roleOfUser) async {
    try {
      final loc.LocationData _locationResult = await location.getLocation();
      var returedData = searchForNearestAmbulance(_locationResult, nameOfUser);
      await FirebaseFirestore.instance.collection('location').doc(nameOfUser).set({
        'latitude': _locationResult.latitude,
        'longitude': _locationResult.longitude,
        'name': nameOfUser,
      }, SetOptions(merge: true));
    }
    catch (e) {
      print(e);
    }
  }

  Future <void> _listenLocation(String nameOfUser, String roleOfUser) async {
    // _stopListening();
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentLocation) async {
      await FirebaseFirestore.instance.collection('location').doc(nameOfUser).set({
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
        'name': nameOfUser,
      }, SetOptions(merge: true));
    });
  }

  _stopListening() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print("Location Status Granted");
    }
    else if (status.isDenied) {
      _requestPermission();
    }
    else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}