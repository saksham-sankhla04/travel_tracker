class TripSurveyModel {
  final String id;
  final DateTime tripStartTime;
  final DateTime tripEndTime;
  final String tripPurpose;
  final String modeOfTransport;
  final int numberOfPassengers;
  final DateTime surveyCompletedAt;

  const TripSurveyModel({
    required this.id,
    required this.tripStartTime,
    required this.tripEndTime,
    required this.tripPurpose,
    required this.modeOfTransport,
    required this.numberOfPassengers,
    required this.surveyCompletedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripStartTime': tripStartTime.toIso8601String(),
        'tripEndTime': tripEndTime.toIso8601String(),
        'tripPurpose': tripPurpose,
        'modeOfTransport': modeOfTransport,
        'numberOfPassengers': numberOfPassengers,
        'surveyCompletedAt': surveyCompletedAt.toIso8601String(),
      };

  factory TripSurveyModel.fromJson(Map<String, dynamic> json) =>
      TripSurveyModel(
        id: json['id'] as String,
        tripStartTime: DateTime.parse(json['tripStartTime'] as String),
        tripEndTime: DateTime.parse(json['tripEndTime'] as String),
        tripPurpose: json['tripPurpose'] as String,
        modeOfTransport: json['modeOfTransport'] as String,
        numberOfPassengers: json['numberOfPassengers'] as int,
        surveyCompletedAt: DateTime.parse(json['surveyCompletedAt'] as String),
      );
}
