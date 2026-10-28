class PredictionModel {
  String? place_id;
  String? main_text;
  String? secondary_text;

  PredictionModel({this.place_id, this.main_text, this.secondary_text});

  /// Legacy Places Autocomplete JSON
  PredictionModel.fromJson(Map<String, dynamic> json) {
    place_id = json["place_id"];
    final structured = json["structured_formatting"];
    if (structured is Map) {
      main_text = structured["main_text"]?.toString();
      secondary_text = structured["secondary_text"]?.toString();
    }
  }

  /// Places API (New) placePrediction object
  factory PredictionModel.fromPlacesNew(Map<String, dynamic> placePrediction) {
    final structured = placePrediction["structuredFormat"];
    String? mainText;
    String? secondaryText;
    if (structured is Map) {
      mainText = structured["mainText"]?["text"]?.toString();
      secondaryText = structured["secondaryText"]?["text"]?.toString();
    }
    mainText ??= placePrediction["text"]?["text"]?.toString();

    return PredictionModel(
      place_id: placePrediction["placeId"]?.toString(),
      main_text: mainText,
      secondary_text: secondaryText,
    );
  }
}
