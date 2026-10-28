import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uber_users_app/models/online_nearby_drivers.dart';

class ManageDriversMethods {
  static List<OnlineNearbyDrivers> nearbyOnlineDriversList = [];

  static void removeDriverFromList(String driverId) {
    int index = nearbyOnlineDriversList
        .indexWhere((driver) => driver.uidDriver == driverId);

    if (index != -1) {
      nearbyOnlineDriversList.removeAt(index);
    }
  }

  static void updateOnlineNearbyDriversLocation(
      OnlineNearbyDrivers nearbyOnlineDriverInformation) {
    int index = nearbyOnlineDriversList.indexWhere((driver) =>
        driver.uidDriver == nearbyOnlineDriverInformation.uidDriver);

    if (index != -1) {
      nearbyOnlineDriversList[index].latDriver =
          nearbyOnlineDriverInformation.latDriver;
      nearbyOnlineDriversList[index].lngDriver =
          nearbyOnlineDriverInformation.lngDriver;
    }
  }

  static void upsertDriver(OnlineNearbyDrivers driver) {
    if (driver.uidDriver == null) return;
    int index = nearbyOnlineDriversList
        .indexWhere((d) => d.uidDriver == driver.uidDriver);
    if (index == -1) {
      nearbyOnlineDriversList.add(driver);
    } else {
      nearbyOnlineDriversList[index].latDriver = driver.latDriver;
      nearbyOnlineDriversList[index].lngDriver = driver.lngDriver;
    }
  }

  /// Reliable fallback: read GeoFire `onlineDrivers` nodes directly from RTDB
  /// and keep drivers within [radiusKm] of the user.
  static Future<List<OnlineNearbyDrivers>> loadOnlineDriversFromFirebase({
    required double userLat,
    required double userLng,
    double radiusKm = 50,
  }) async {
    final List<OnlineNearbyDrivers> found = [];

    try {
      final snapshot =
          await FirebaseDatabase.instance.ref().child("onlineDrivers").get();

      if (!snapshot.exists || snapshot.value == null) {
        print("onlineDrivers node is empty or missing");
        return found;
      }

      final raw = snapshot.value;
      if (raw is! Map) {
        print("onlineDrivers unexpected type: ${raw.runtimeType}");
        return found;
      }

      raw.forEach((key, value) {
        if (value is! Map) return;

        final coords = _parseLatLng(value);
        if (coords == null) return;

        final distanceMeters = Geolocator.distanceBetween(
          userLat,
          userLng,
          coords.$1,
          coords.$2,
        );

        if (distanceMeters <= radiusKm * 1000) {
          final driver = OnlineNearbyDrivers();
          driver.uidDriver = key.toString();
          driver.latDriver = coords.$1;
          driver.lngDriver = coords.$2;
          found.add(driver);
          upsertDriver(driver);
        }
      });

      print("Found ${found.length} online driver(s) within ${radiusKm}km");
    } catch (e) {
      print("loadOnlineDriversFromFirebase error: $e");
    }

    return found;
  }

  /// GeoFire stores location as `l: [lat, lng]` (list or map with 0/1).
  static (double, double)? _parseLatLng(Map value) {
    final dynamic location = value["l"];
    if (location == null) return null;

    try {
      if (location is List && location.length >= 2) {
        return (
          double.parse(location[0].toString()),
          double.parse(location[1].toString()),
        );
      }
      if (location is Map) {
        final lat = location["0"] ?? location[0];
        final lng = location["1"] ?? location[1];
        if (lat != null && lng != null) {
          return (double.parse(lat.toString()), double.parse(lng.toString()));
        }
      }
    } catch (_) {}
    return null;
  }
}
