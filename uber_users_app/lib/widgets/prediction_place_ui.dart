import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/models/address_models.dart';
import 'package:uber_users_app/models/prediction_model.dart';
import 'package:uber_users_app/widgets/loading_dialog.dart';

class PredictionPlaceUI extends StatefulWidget {
  PredictionModel? predictedPlaceData;

  PredictionPlaceUI({super.key, this.predictedPlaceData});

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}

class _PredictionPlaceUIState extends State<PredictionPlaceUI> {
  fetchClickedPlaceDetails(String placeId) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Getting details..."),
    );

    // Places API (New) place details
    final encodedPlaceId = Uri.encodeComponent(placeId);
    final urlPlaceDetailAPI =
        "https://places.googleapis.com/v1/places/$encodedPlaceId";

    final responseFromPlaceDetailsAPI =
        await CommonMethods.sendAuthorizedRequestToAPI(
      apiUrl: urlPlaceDetailAPI,
      method: "GET",
      headers: {
        "X-Goog-Api-Key": googleMapKey,
        "X-Goog-FieldMask": "id,displayName,formattedAddress,location",
      },
    );

    if (!mounted) return;
    Navigator.pop(context); // close loading dialog

    if (responseFromPlaceDetailsAPI == "error") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch place details.")),
      );
      return;
    }

    if (responseFromPlaceDetailsAPI is Map &&
        responseFromPlaceDetailsAPI["error"] != null) {
      final message =
          responseFromPlaceDetailsAPI["error"]["message"]?.toString() ??
              "Place details denied.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    final location = responseFromPlaceDetailsAPI["location"];
    if (location is! Map ||
        location["latitude"] == null ||
        location["longitude"] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Place location missing from response.")),
      );
      return;
    }

    final AddressModel dropOffLocation = AddressModel();
    dropOffLocation.placeName =
        responseFromPlaceDetailsAPI["displayName"]?["text"]?.toString() ??
            responseFromPlaceDetailsAPI["formattedAddress"]?.toString() ??
            widget.predictedPlaceData?.main_text;
    dropOffLocation.humanReadableAddress =
        responseFromPlaceDetailsAPI["formattedAddress"]?.toString() ??
            dropOffLocation.placeName;
    dropOffLocation.latitudePosition =
        (location["latitude"] as num).toDouble();
    dropOffLocation.longitudePosition =
        (location["longitude"] as num).toDouble();
    dropOffLocation.placeID = placeId;

    Provider.of<AppInfoClass>(context, listen: false)
        .updateDropOffLocation(dropOffLocation);

    Navigator.pop(context, "placeSelected");
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final placeId = widget.predictedPlaceData?.place_id;
        if (placeId == null || placeId.isEmpty) return;
        fetchClickedPlaceDetails(placeId);
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(0))),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.share_location,
                color: Colors.grey,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      widget.predictedPlaceData?.main_text ?? "",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.predictedPlaceData?.secondary_text ?? "",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
