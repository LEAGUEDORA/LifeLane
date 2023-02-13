import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frontned/mymap.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("Ready to Init");
  await Firebase.initializeApp();
  print("Init");
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  @override
  void initState() {
    super.initState();
    _requestPermission();
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
            _getLocation();
          }, child: const Text("Add my location")),
          TextButton(onPressed: () {
            _listenLocation();
          }, child: const Text("enable live location")),
          TextButton(onPressed: () {
            _stopListening();
          }, child: const Text("Stop live location")),
          Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('location').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                    itemCount: snapshot.data?.docs.length,
                    itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(snapshot.data!.docs[index]['name'].toString()),
                    subtitle: Row(
                      children: [
                        Text(snapshot.data!.docs[index]['latitude'].toString()),
                        const SizedBox(
                          width: 20,
                        ),
                        Text(snapshot.data!.docs[index]['longitude'].toString()),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.directions),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => MyMap(snapshot.data!.docs[index].id))
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

  _getLocation() async {
    try {
      final loc.LocationData _locationResult = await location.getLocation();
      await FirebaseFirestore.instance.collection('location').doc('user1').set({
        'latitude': _locationResult.latitude,
        'longitude': _locationResult.longitude,
        'name': "John"
      }, SetOptions(merge: true));
    }
    catch (e) {
      print(e);
    }
  }

  Future <void> _listenLocation() async {
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentLocation) async {
      await FirebaseFirestore.instance.collection('location').doc('user1').set({
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
        'name': "John"
      }, SetOptions(merge: true));
    });
  }

  _stopListening() {
  _locationSubscription?.cancel();
  setState(() {
    _locationSubscription = null;
  });
  }

  _requestPermission () async {
  var status = await Permission.location.request();
  if (status.isGranted){
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
