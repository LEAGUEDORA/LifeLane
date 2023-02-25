import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:frontned/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;


class MyMap extends StatefulWidget {
  final String user_id;

  MyMap(this.user_id);

  @override
  _MyMapState createState() => _MyMapState();
}


class _MyMapState extends State<MyMap> {
  final loc.Location location = loc.Location();
  late GoogleMapController _controller;
  bool _added = false;
  late double sourceLatitude;
  late double sourceLongitude;
  StreamSubscription<loc.LocationData>? _locationSubscription;
  List<LatLng> polyLineCoordinates = [];
  bool gotPolyLines = false;


  @override
  void initState(){
    super.initState();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async{
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      }
      );
    }).listen((loc.LocationData currentLocation) async {
      if (!mounted){
        return;
      }
        setState(() {
          sourceLatitude = currentLocation.latitude!;
          sourceLongitude = currentLocation.longitude!;
        });
    }
    );
  }

  @override
  void dispose() {

    super.dispose();
  }

  void getPolyPoints(LatLng destinationLocation) async {
    PolylinePoints polyLinePoints = PolylinePoints();

    // PointLatLng(sourceLatitude!, sourceLatitude!),
    // PointLatLng(destinationLocation.latitude, destinationLocation.longitude));
    if (!gotPolyLines){
      PolylineResult result = await polyLinePoints.getRouteBetweenCoordinates(
          googleAPIKEY,
          PointLatLng(sourceLatitude, sourceLongitude),
          PointLatLng(destinationLocation.latitude, destinationLocation.longitude));
      print("Result");
      print(sourceLatitude);
      print(result.points.toString());
      if (result.points.isNotEmpty) {
        polyLineCoordinates = [];
        result.points.forEach(
                (PointLatLng point) =>
                    polyLineCoordinates.add(LatLng(point.latitude, point.longitude)));
      }
      setState(() {
        gotPolyLines = true;
      });
    }

  }

  @override
  Widget build(BuildContext context){

    return Scaffold(body: StreamBuilder(
      stream: FirebaseFirestore.instance.collection('location').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (_added) {
          mymap(snapshot);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        LatLng destinationLocation = LatLng(snapshot.data!.docs.singleWhere((element) => element.id == widget.user_id)['latitude'], snapshot.data!.docs.singleWhere(
                (element) => element.id == widget.user_id)['longitude'] as double);
        getPolyPoints(destinationLocation);
        return GoogleMap(
          mapType: MapType.normal,
          markers: {
            Marker(position: LatLng(sourceLatitude!, sourceLongitude!),
                markerId: const MarkerId("source"),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
            Marker(position: destinationLocation,
                markerId: const MarkerId("destination"),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta)),

          },
          initialCameraPosition: CameraPosition(target: destinationLocation,
              zoom: 14.47
          ),
          polylines: {
            Polyline(
                polylineId: PolylineId("source_dest_route"),
                points: polyLineCoordinates,
                width: 4,
              color: Colors.blue
            )
          },
          onMapCreated: (GoogleMapController controller) async {
            setState(() {
              _controller = controller;
              _added = true;
            });
          },
        );
      },));
  }

  Future<void> mymap(AsyncSnapshot<QuerySnapshot> snapshot) async {
    await _controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(snapshot.data!.docs.singleWhere(
            (element) => element.id == widget.user_id)['latitude'],
        snapshot.data!.docs.singleWhere(
                (element) => element.id == widget.user_id)['longitude'] as double),
        zoom: 14.47,
    )));
  }
}