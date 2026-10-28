import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/models/address_models.dart';

import '../models/direction_details.dart';

class CommonMethods {
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();

    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) {
      if (!context.mounted) return;
      displaySnackBar(
          "Your Internet is not Available. Check your connection. Try Again.",
          context);
    }
  }

  displaySnackBar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static sendRequestToAPI(String apiUrl) async {
    try {
      http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));
      if (responseFromAPI.statusCode == 200) {
        return jsonDecode(responseFromAPI.body);
      }
      print('API GET error ${responseFromAPI.statusCode}: ${responseFromAPI.body}');
      return "error";
    } catch (errorMsg) {
      print(errorMsg);
      return "error";
    }
  }

  /// Places API (New) / other Google JSON APIs that need custom headers.
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

  ///Reverse GeoCoding
  static Future<String> convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
      Position position, BuildContext context) async {
    String humanReadableAddress = "";
    String apiGeoCodingUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey";

    var responseFromAPI = await sendRequestToAPI(apiGeoCodingUrl);

    if (responseFromAPI != "error") {
      final results = responseFromAPI["results"];
      if (results is List && results.isNotEmpty) {
        humanReadableAddress = results[0]["formatted_address"] ?? "";

        AddressModel model = AddressModel();
        model.humanReadableAddress = humanReadableAddress;
        model.placeName = humanReadableAddress;
        model.longitudePosition = position.longitude;
        model.latitudePosition = position.latitude;

        Provider.of<AppInfoClass>(context, listen: false)
            .updatePickUpLocation(model);
      } else {
        // Usually means googleMapKey is empty/invalid or Geocoding API is disabled.
        print(
            "Geocoding returned no results. Check googleMapKey and enable Geocoding API. status=${responseFromAPI["status"]} error=${responseFromAPI["error_message"]}");
        humanReadableAddress =
            "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";

        AddressModel model = AddressModel();
        model.humanReadableAddress = humanReadableAddress;
        model.placeName = "Current location";
        model.longitudePosition = position.longitude;
        model.latitudePosition = position.latitude;

        Provider.of<AppInfoClass>(context, listen: false)
            .updatePickUpLocation(model);
      }
    }

    return humanReadableAddress;
  }

  /// This method shortens the full address by extracting key parts.
  static String shortenAddress(String fullAddress) {
    // Split the address by commas
    List<String> parts = fullAddress.split(',');

    // Return a shorter version of the address: e.g., "Street Name, City"
    if (parts.length >= 2) {
      return "${parts[0].trim()}, ${parts[1].trim()}";
    }

    // If the address has fewer parts, return it as is
    return fullAddress;
  }

  static Future<DirectionDetails?> getDirectionDetailsFromAPI(
      LatLng source, LatLng destination) async {
    // Routes API (New)
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

      final directionDetails = DirectionDetails();
      directionDetails.distanceValueDigit = distanceMeters;
      directionDetails.durationValueDigit = durationSeconds;
      directionDetails.distanceTextString = distanceMeters >= 1000
          ? "${(distanceMeters / 1000).toStringAsFixed(1)} km"
          : "$distanceMeters m";
      directionDetails.durationTextString = durationSeconds >= 60
          ? "${(durationSeconds / 60).ceil()} mins"
          : "$durationSeconds sec";
      directionDetails.encodedPoints = encodedPoints;
      return directionDetails;
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
        (directionDetails.distanceValueDigit! / 1000) * distancePerKmAmountPKR;
    double totalDurationSpendFareAmountPKR =
        (directionDetails.durationValueDigit! / 60) *
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

  // Utility function to format time from total minutes into "X hours Y mins"
  String formatTime(int totalMinutes) {
    int hours = totalMinutes ~/ 60; // Get the number of full hours
    int minutes = totalMinutes % 60; // Get the remaining minutes
    if (hours > 0) {
      return "$hours hours $minutes mins";
    } else {
      return "$minutes mins"; // If there are no hours, just show minutes
    }
  }
}
