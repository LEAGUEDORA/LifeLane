
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frontned/mymap.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class MyApp extends StatefulWidget {
  String nameOfUser;
  MyApp({Key? key, required this.nameOfUser}): super(key: key);

  @override
  _MyAppState createState() => _MyAppState(nameOfUser: nameOfUser);
}

class _MyAppState extends State<MyApp> {
  String nameOfUser;
  _MyAppState({required this.nameOfUser});

  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    location.changeSettings(interval: 30, accuracy: loc.LocationAccuracy.high);
    location.enableBackgroundMode(enable: true);
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
            _getLocation(nameOfUser);
            _listenLocation(nameOfUser);
          }, child: const Text("Call for Ambulance")),
          // TextButton(onPressed: () {
          //   _listenLocation(nameOfUser);
          // }, child: const Text("enable live location")),
          // TextButton(onPressed: () {
          //   _stopListening();
          // }, child: const Text("Stop live location")),
          Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('location')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(snapshot.data!.docs[index]['name']
                              .toString()),
                          subtitle: Row(
                            children: [
                              Text(snapshot.data!.docs[index]['latitude']
                                  .toString()),
                               SizedBox(
                                width: 20,
                              ),
                              Text(snapshot.data!.docs[index]['longitude']
                                  .toString()),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.directions),
                            onPressed: () {
                              Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) =>
                                      MyMap(snapshot.data!.docs[index].id))
                              );
                            },
                          ),
                        );
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
        double distanceInMeters = Geolocator.distanceBetween(currentLocation.latitude!, currentLocation.longitude!, data['latitude'], data['longitude']);
        if (distanceInMeters < maximum && nameOfUser != data['name']) {
          maximum = distanceInMeters;
          name = data['name'];
        }
      }
    });
    return [maximum, name];

  }

  _getLocation(String nameOfUser) async {
    try {
      final loc.LocationData _locationResult = await location.getLocation();
      var returedData = searchForNearestAmbulance(_locationResult, nameOfUser);
      returedData.then(
              (value) {
                print(value);
              }
      );
      await FirebaseFirestore.instance.collection('location').doc(nameOfUser).set({
        'latitude': _locationResult.latitude,
        'longitude': _locationResult.longitude,
        'name': nameOfUser
      }, SetOptions(merge: true));
    }
    catch (e) {
      print(e);
    }
  }

  Future <void> _listenLocation(String nameOfUser) async {
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
        'name': nameOfUser
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