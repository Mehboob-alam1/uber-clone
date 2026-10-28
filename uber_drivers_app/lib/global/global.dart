import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = '';
String userEmail = '';
const String googleMapKey = "YOUR_GOOGLE_MAPS_API_KEY";
const CameraPosition  googlePlexInitialPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);

StreamSubscription<Position>? positionStreamHomePage;
StreamSubscription<Position>? positionStreamNewTripPage;


int driverTripRequestTimeout = 40;

final AudioPlayer audioPlayer = AudioPlayer();

Position? driverCurrentPosition;

String driverName = "";
String driverPhone = "";
String driverPhoto = "";
String driverEmail = "";
String carModel = "";
String carColor = "";
String carNumber = "";
String driverSecondName = "";
String address = "";
String ratting = "";
String bidAmount = "";
String fareAmount = "";
