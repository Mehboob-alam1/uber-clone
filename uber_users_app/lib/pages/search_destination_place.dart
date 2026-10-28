import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/global/global_var.dart';
import 'package:uber_users_app/main.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/models/prediction_model.dart';
import 'package:uber_users_app/widgets/prediction_place_ui.dart';

class SearchDestinationPlace extends StatefulWidget {
  const SearchDestinationPlace({super.key});

  @override
  State<SearchDestinationPlace> createState() => _SearchDestinationPlaceState();
}

class _SearchDestinationPlaceState extends State<SearchDestinationPlace> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController =
      TextEditingController();

  List<PredictionModel> dropOffPredictionsPlacesList = [];
  String? searchError;
  bool isSearching = false;

  searchLocation(String locationName) async {
    if (locationName.trim().length < 2) {
      if (mounted) {
        setState(() {
          dropOffPredictionsPlacesList = [];
          searchError = null;
        });
      }
      return;
    }

    if (googleMapKey.isEmpty) {
      if (mounted) {
        setState(() {
          searchError = "Google Maps API key is missing.";
          dropOffPredictionsPlacesList = [];
        });
      }
      return;
    }

    setState(() {
      isSearching = true;
      searchError = null;
    });

    // Places API (New)
    const apiPlacesUrl = "https://places.googleapis.com/v1/places:autocomplete";
    final responseFromPlacesAPI =
        await CommonMethods.sendAuthorizedRequestToAPI(
      apiUrl: apiPlacesUrl,
      method: "POST",
      headers: {
        "X-Goog-Api-Key": googleMapKey,
      },
      body: {
        "input": locationName.trim(),
        "includedRegionCodes": ["pk"],
      },
    );

    if (!mounted) return;

    setState(() {
      isSearching = false;
    });

    if (responseFromPlacesAPI == "error") {
      setState(() {
        dropOffPredictionsPlacesList = [];
        searchError = "Could not search places. Check your connection.";
      });
      return;
    }

    if (responseFromPlacesAPI is Map &&
        responseFromPlacesAPI["error"] != null) {
      final message = responseFromPlacesAPI["error"]["message"]?.toString() ??
          "Places search denied.";
      setState(() {
        dropOffPredictionsPlacesList = [];
        searchError =
            "$message\nEnable Places API (New) and allow it on your API key.";
      });
      return;
    }

    final suggestions = responseFromPlacesAPI["suggestions"];
    if (suggestions is! List || suggestions.isEmpty) {
      setState(() {
        dropOffPredictionsPlacesList = [];
        searchError = "No places found.";
      });
      return;
    }

    final predictionsList = suggestions
        .whereType<Map>()
        .map((item) => item["placePrediction"])
        .whereType<Map>()
        .map((prediction) =>
            PredictionModel.fromPlacesNew(Map<String, dynamic>.from(prediction)))
        .where((p) => (p.place_id ?? "").isNotEmpty)
        .toList();

    setState(() {
      dropOffPredictionsPlacesList = predictionsList;
      searchError = predictionsList.isEmpty ? "No places found." : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    String userAddress = Provider.of<AppInfoClass>(context, listen: false)
            .pickUpLocation
            ?.humanReadableAddress ??
        '';

    pickUpTextEditingController.text = userAddress;
    mq = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 24, top: 20, right: 24, bottom: 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                            ),
                            const Center(
                              child: Text(
                                "Set Dropoff Location",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Image.asset(
                              "assets/images/initial.png",
                              height: 16,
                              width: 16,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white60,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: TextField(
                                    controller: pickUpTextEditingController,
                                    decoration: const InputDecoration(
                                      hintText: "Pickup Address",
                                      fillColor: Colors.white60,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                          left: 11, top: 9, bottom: 9),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Image.asset(
                              "assets/images/final.png",
                              height: 16,
                              width: 16,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white60,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: TextField(
                                    controller:
                                        destinationTextEditingController,
                                    onChanged: (value) {
                                      searchLocation(value);
                                    },
                                    decoration: const InputDecoration(
                                      hintText: "Destination Address",
                                      fillColor: Colors.white60,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                          left: 11, top: 9, bottom: 9),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isSearching)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              if (searchError != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    searchError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              if (dropOffPredictionsPlacesList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 5,
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 5,
                        child: PredictionPlaceUI(
                          predictedPlaceData:
                              dropOffPredictionsPlacesList[index],
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                    itemCount: dropOffPredictionsPlacesList.length,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
