import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../global/global.dart';
import '../main.dart';
import '../methods/common_method.dart';
import '../models/trip_details.dart';
import '../pages/newTrip/new_trip_page.dart';
import 'loading_dialog.dart';

class NotificationDialog extends StatefulWidget {
  final TripDetails? tripDetailsInfo;
  final String? fareAmount;
  final String? bidAmount;

  NotificationDialog({
    super.key,
    this.tripDetailsInfo,
    this.fareAmount,
    this.bidAmount,
  });

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  String tripRequestStatus = "";
  CommonMethods cMethods = CommonMethods();
  late Timer timer;
  bool _accepting = false;

  cancelNotificationDialogAfter20Sec() {
    const oneTickPerSecond = Duration(seconds: 1);

    timer = Timer.periodic(oneTickPerSecond, (timer) {
      driverTripRequestTimeout = driverTripRequestTimeout - 1;

      if (tripRequestStatus == "accepted") {
        timer.cancel();
        driverTripRequestTimeout = 40;
        return;
      }

      if (driverTripRequestTimeout == 0) {
        timer.cancel();
        driverTripRequestTimeout = 40;
        audioPlayer.stop();

        if (mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    cancelNotificationDialogAfter20Sec();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> acceptTripRequest() async {
    if (_accepting) return;
    _accepting = true;

    final tripId = widget.tripDetailsInfo?.tripID;
    if (tripId == null || tripId.isEmpty) {
      cMethods.displaySnackBar("Trip details missing.", context);
      _accepting = false;
      return;
    }

    audioPlayer.stop();
    tripRequestStatus = "accepted";
    timer.cancel();

    // Close the notification dialog first, then work from the root navigator.
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }

    final nav = navigatorKey.currentState;
    final navContext = navigatorKey.currentContext;
    if (nav == null || navContext == null) {
      _accepting = false;
      return;
    }

    showDialog(
      barrierDismissible: false,
      context: navContext,
      builder: (BuildContext context) => const LoadingDialog(
        messageText: 'Please wait...',
      ),
    );

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final driverTripStatusRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(uid)
          .child("newTripStatus");

      final statusSnap = await driverTripStatusRef.get();
      final statusValue = statusSnap.value?.toString() ?? "";

      // Only hard-stop if user clearly cancelled. Timeout / mismatch still
      // allow accept if the tripRequest node exists (same-phone testing).
      if (statusValue == "cancelled") {
        if (nav.canPop()) nav.pop(); // loading
        cMethods.displaySnackBar(
            "Trip Request has been Cancelled by user.", navContext);
        _accepting = false;
        return;
      }

      final tripSnap = await FirebaseDatabase.instance
          .ref()
          .child("tripRequest")
          .child(tripId)
          .get();

      if (!tripSnap.exists) {
        if (nav.canPop()) nav.pop();
        cMethods.displaySnackBar("Trip Request removed. Not Found.", navContext);
        _accepting = false;
        return;
      }

      await driverTripStatusRef.set("accepted");
      await FirebaseDatabase.instance
          .ref()
          .child("tripRequest")
          .child(tripId)
          .child("status")
          .set("accepted");

      cMethods.turnOffLocationUpdatesForHomePage();

      if (nav.canPop()) nav.pop(); // close loading

      await nav.push(
        MaterialPageRoute(
          builder: (c) =>
              NewTripPage(newTripDetailsInfo: widget.tripDetailsInfo),
        ),
      );
    } catch (e) {
      print("acceptTripRequest error: $e");
      if (nav.canPop()) nav.pop();
      cMethods.displaySnackBar("Failed to accept trip. Try again.", navContext);
    } finally {
      _accepting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fareAmount = widget.fareAmount ?? "N/A";
    final String bidAmount =
        widget.bidAmount == "null" || widget.bidAmount == null
            ? "No Bid"
            : "Rs ${widget.bidAmount}";

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.white54,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 15.0),
            Image.asset(
              "assets/images/uberexec.png",
              width: 140,
            ),
            const SizedBox(height: 15.0),
            const Text(
              "NEW TRIP REQUEST",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20.0),
            const Divider(height: 1, color: Colors.black, thickness: 1),
            const SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset("assets/images/initial.png",
                          height: 16, width: 16),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo?.pickupAddress ?? "Unknown",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset("assets/images/final.png",
                          height: 16, width: 16),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo?.dropOffAddress ?? "Unknown",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Actual Fare Amount: Rs $fareAmount",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Bidded Amount: $bidAmount",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Divider(height: 1, color: Colors.black, thickness: 1),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _accepting
                          ? null
                          : () {
                              audioPlayer.stop();
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink),
                      child: const Text(
                        "DECLINE",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _accepting ? null : acceptTripRequest,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text(
                        "ACCEPT",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
