// By @19PA1A0548

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:frontned/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'dart:ui' as ui;

class MyMap extends StatefulWidget {
  final String userId; // Name of the patient

  MyMap(this.userId);

  @override
  _MyMapState createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  final loc.Location location = loc.Location();
  late GoogleMapController _controller;
  bool _added = false;
  double? sourceLatitude;
  double? sourceLongitude;
  StreamSubscription<loc.LocationData>? _locationSubscription;
  List<LatLng> polyLineCoordinates = [];
  bool gotPolyLines = false;
  Set<Marker> markers = {};
  BitmapDescriptor driver = BitmapDescriptor.defaultMarker;
  BitmapDescriptor patient = BitmapDescriptor.defaultMarker;
  BitmapDescriptor police = BitmapDescriptor.defaultMarker;

  static Future<Uint8List?> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        ?.buffer
        .asUint8List();
  }

  @override
  void initState() {
    getBytesFromAsset("assets/police.png", 64).then((onValue) {
      police = BitmapDescriptor.fromBytes(onValue!);
    });
    getBytesFromAsset("assets/ambulance.jpg", 64).then((onValue) {
      driver = BitmapDescriptor.fromBytes(onValue!);
    });
    getBytesFromAsset("assets/patient.png", 64).then((onValue) {
      patient = BitmapDescriptor.fromBytes(onValue!);
    });

    super.initState();
    getCurrentLocation();
    // getImageMarkers();
  }

  Future<void> getCurrentLocation() async {
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentLocation) async {
      if (!mounted) {
        return;
      }
      setState(() {
        // print("Setting state");
        sourceLatitude = currentLocation.latitude!;
        sourceLongitude = currentLocation.longitude!;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  LatLng getDriver(name, snapshot) {
    // print(name);
    LatLng patient = LatLng(
        snapshot.data!.docs
            .singleWhere((element) => element['name'] == name)['latitude'],
        snapshot.data!.docs
            .singleWhere((element) => element['name'] == name)['longitude']);
    return patient;
  }

  List<LatLng> getSourceAndDestination(snapshot) {
    LatLng patient = LatLng(
        snapshot.data!.docs
            .singleWhere((element) => element.id == widget.userId)['latitude'],
        snapshot.data!.docs.singleWhere(
            (element) => element.id == widget.userId)['longitude'] as double);
    LatLng driver = getDriver(
        snapshot.data!.docs
            .singleWhere((element) => element.id == widget.userId)['driver'],
        snapshot);

    return [patient, driver];
  }

  void getPolyPoints(snapshot) async {
    List<LatLng> points = getSourceAndDestination(snapshot);
    PolylinePoints polyLinePoints = PolylinePoints();

    if (!gotPolyLines) {
      PolylineResult result = await polyLinePoints.getRouteBetweenCoordinates(
          googleAPIKEY,
          PointLatLng(points[0].latitude, points[0].longitude),
          PointLatLng(points[1].latitude, points[1].longitude));
      if (result.points.isNotEmpty) {
        polyLineCoordinates = [];
        for (var point in result.points) {
          polyLineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      }
      setState(() {
        gotPolyLines = true;
      });
    }
  }

  Set<Marker> getPoilceMarkers(snapshot) {
    List<LatLng> locations = getSourceAndDestination(snapshot);
    late final stream =
        FirebaseFirestore.instance.collection('location').snapshots();

    stream.forEach((element) {
      for (var doc in element.docs) {
        if (doc['role'] == "police") {
          markers.add(
            Marker(
                position: LatLng(doc['latitude'], doc['longitude']),
                markerId: MarkerId("police ${doc['name']}"),
                icon: police),
          );
        }
      }
    });

    markers.add(
      Marker(
          position: LatLng(locations[0].latitude, locations[0].longitude),
          markerId: const MarkerId("patient"), // Patient
          icon: patient),
    );
    markers.add(
      Marker(
          position: LatLng(locations[1].latitude, locations[1].longitude),
          markerId: const MarkerId("driver"), // Driver
          icon: driver),
    );

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    late final stream =
        FirebaseFirestore.instance.collection('location').snapshots();
    return Scaffold(
        appBar: AppBar(title: const Text("Track it")),
        body: StreamBuilder(
          stream: stream,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (_added) {
              mymap(snapshot);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            LatLng destinationLocation = LatLng(
                snapshot.data!.docs.singleWhere(
                    (element) => element.id == widget.userId)['latitude'],
                snapshot.data!.docs.singleWhere(
                        (element) => element.id == widget.userId)['longitude']
                    as double);
            getPolyPoints(snapshot);
            return GoogleMap(
              mapType: MapType.normal,
              markers: getPoilceMarkers(snapshot),
              initialCameraPosition:
                  CameraPosition(target: destinationLocation, zoom: 14.47),
              polylines: {
                Polyline(
                    polylineId: const PolylineId("source_dest_route"),
                    points: polyLineCoordinates,
                    width: 4,
                    color: Colors.blue)
              },
              onMapCreated: (GoogleMapController controller) async {
                setState(() {
                  _controller = controller;
                  _added = true;
                });
              },
            );
          },
        ));
  }

  Future<void> mymap(AsyncSnapshot<QuerySnapshot> snapshot) async {
    await _controller
        .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(
          snapshot.data!.docs.singleWhere(
              (element) => element.id == widget.userId)['latitude'],
          snapshot.data!.docs.singleWhere(
              (element) => element.id == widget.userId)['longitude'] as double),
      zoom: 14.5,
    )));
  }
}
