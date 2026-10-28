import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uber_drivers_app/const.dart';
import '../global/global.dart';
import '../models/direction_details.dart';

class CommonMethods {
  Future<void> checkConnectivity(BuildContext context) async {
    var connectionResults = await Connectivity().checkConnectivity();
    print("Connectivity result: $connectionResults"); // Add this line

    if (connectionResults != ConnectivityResult.wifi &&
        connectionResults != ConnectivityResult.mobile) {
      if (!context.mounted) return;
      displaySnackBar(
          "Your internet is not working. Check your connection. Try again.",
          context);
    } else {
      print("Internet is working"); // Add this line
    }
  }

  void displaySnackBar(String message, BuildContext context) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void turnOffLocationUpdatesForHomePage() {
    if (positionStreamHomePage != null) {
      positionStreamHomePage!.pause();
    } else {
      // Handle the case where the stream is null (optional)
      print("positionStreamHomePage is null, cannot pause.");
    }
  }

  void turnOnLocationUpdatesForHomePage() {
    // Check if positionStreamHomePage is not null before resuming
    if (positionStreamHomePage != null) {
      positionStreamHomePage!.resume();
    } else {
      // Handle the case where the stream is null (optional)
      print("positionStreamHomePage is null, cannot resume.");
    }

    // Check if driverCurrentPosition is not null before updating Geofire
    if (driverCurrentPosition != null) {
      Geofire.setLocation(
        FirebaseAuth.instance.currentUser!.uid,
        driverCurrentPosition!.latitude,
        driverCurrentPosition!.longitude,
      );
    } else {
      // Handle the case where driverCurrentPosition is null (optional)
      print("driverCurrentPosition is null, cannot update Geofire.");
    }
  }

  static sendRequestToAPI(String apiUrl) async {
    http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));

    try {
      if (responseFromAPI.statusCode == 200) {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      } else {
        return "error";
      }
    } catch (errorMsg) {
      return "error";
    }
  }

  static Future<dynamic> sendAuthorizedRequestToAPI({
    required String apiUrl,
    String method = "GET",
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final uri = Uri.parse(apiUrl);
      final requestHeaders = <String, String>{
        "Content-Type": "application/json",
        ...?headers,
      };
      late http.Response response;
      if (method.toUpperCase() == "POST") {
        response = await http.post(
          uri,
          headers: requestHeaders,
          body: body is String ? body : jsonEncode(body),
        );
      } else {
        response = await http.get(uri, headers: requestHeaders);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return <String, dynamic>{};
        return jsonDecode(response.body);
      }

      print('API $method error ${response.statusCode}: ${response.body}');
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return "error";
      }
    } catch (errorMsg) {
      print(errorMsg);
      return "error";
    }
  }

  /// Routes API (New) — legacy Directions API is blocked on this key.
  static Future<DirectionDetails?> getDirectionDetailsFromAPI(
      LatLng source, LatLng destination) async {
    const urlRoutesAPI =
        "https://routes.googleapis.com/directions/v2:computeRoutes";

    final responseFromDirectionAPI = await sendAuthorizedRequestToAPI(
      apiUrl: urlRoutesAPI,
      method: "POST",
      headers: {
        "X-Goog-Api-Key": googleMapKey,
        "X-Goog-FieldMask":
            "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline",
      },
      body: {
        "origin": {
          "location": {
            "latLng": {
              "latitude": source.latitude,
              "longitude": source.longitude,
            }
          }
        },
        "destination": {
          "location": {
            "latLng": {
              "latitude": destination.latitude,
              "longitude": destination.longitude,
            }
          }
        },
        "travelMode": "DRIVE",
        "routingPreference": "TRAFFIC_AWARE",
      },
    );

    if (responseFromDirectionAPI == "error") {
      print("Error in Routes API response");
      return null;
    }

    if (responseFromDirectionAPI is Map &&
        responseFromDirectionAPI["error"] != null) {
      print(
          "Routes API error: ${responseFromDirectionAPI["error"]["message"]}");
      return null;
    }

    final routes = responseFromDirectionAPI["routes"];
    if (routes is! List || routes.isEmpty) {
      print("No routes found in the response.");
      return null;
    }

    try {
      final route = routes[0] as Map<String, dynamic>;
      final distanceMeters = (route["distanceMeters"] as num?)?.toInt() ?? 0;
      final durationRaw = route["duration"]?.toString() ?? "0s";
      final durationSeconds =
          int.tryParse(durationRaw.replaceAll(RegExp(r'[^0-9]'), "")) ?? 0;
      final encodedPoints =
          route["polyline"]?["encodedPolyline"]?.toString() ?? "";

      if (encodedPoints.isEmpty) {
        print("Route polyline missing.");
        return null;
      }

      final detailsModel = DirectionDetails();
      detailsModel.distanceValueDigits = distanceMeters;
      detailsModel.durationValueDigits = durationSeconds;
      detailsModel.distanceTextString = distanceMeters >= 1000
          ? "${(distanceMeters / 1000).toStringAsFixed(1)} km"
          : "$distanceMeters m";
      detailsModel.durationTextString = durationSeconds >= 60
          ? "${(durationSeconds / 60).ceil()} mins"
          : "$durationSeconds sec";
      detailsModel.encodedPoints = encodedPoints;
      return detailsModel;
    } catch (e) {
      print("Error processing Routes API response: $e");
      return null;
    }
  }

  calculateFareAmountInPKR(DirectionDetails directionDetails,
      {double surgeMultiplier = 1.0}) {
    double distancePerKmAmountPKR = 20; // 20 PKR per km
    double durationPerMinuteAmountPKR = 15; // 15 PKR per minute
    double baseFareAmountPKR = 150; // Base fare in PKR
    double bookingFeePKR = 50; // Booking fee in PKR
    double minimumFarePKR = 200; // Minimum fare in PKR

    // Calculate fare based on distance and time
    double totalDistanceTravelledFareAmountPKR =
        (directionDetails.distanceValueDigits! / 1000) * distancePerKmAmountPKR;
    double totalDurationSpendFareAmountPKR =
        (directionDetails.durationValueDigits! / 60) *
            durationPerMinuteAmountPKR;

    // Total fare before applying surge
    double totalFareBeforeSurgePKR = baseFareAmountPKR +
        totalDistanceTravelledFareAmountPKR +
        totalDurationSpendFareAmountPKR +
        bookingFeePKR;

    // Apply surge pricing
    double overAllTotalFareAmountPKR =
        totalFareBeforeSurgePKR * surgeMultiplier;

    // Apply minimum fare
    if (overAllTotalFareAmountPKR < minimumFarePKR) {
      overAllTotalFareAmountPKR = minimumFarePKR;
    }

    return overAllTotalFareAmountPKR.toStringAsFixed(2);
  }
}
