class TripSurveyModel {
  final String id;
  final DateTime tripStartTime;
  final DateTime tripEndTime;
  final String tripPurpose;
  final String modeOfTransport;
  final int numberOfPassengers;
  final DateTime surveyCompletedAt;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final bool isSynced;

  const TripSurveyModel({
    required this.id,
    required this.tripStartTime,
    required this.tripEndTime,
    required this.tripPurpose,
    required this.modeOfTransport,
    required this.numberOfPassengers,
    required this.surveyCompletedAt,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.isSynced = false,
  });

  TripSurveyModel copyWith({bool? isSynced}) => TripSurveyModel(
        id: id,
        tripStartTime: tripStartTime,
        tripEndTime: tripEndTime,
        tripPurpose: tripPurpose,
        modeOfTransport: modeOfTransport,
        numberOfPassengers: numberOfPassengers,
        surveyCompletedAt: surveyCompletedAt,
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        isSynced: isSynced ?? this.isSynced,
      );

  /// JSON sent to the backend (excludes local-only fields like id, isSynced).
  Map<String, dynamic> toApiJson() {
    final json = <String, dynamic>{
      'tripStartTime': tripStartTime.toIso8601String(),
      'tripEndTime': tripEndTime.toIso8601String(),
      'tripPurpose': tripPurpose,
      'modeOfTransport': modeOfTransport,
      'numberOfPassengers': numberOfPassengers,
      'surveyCompletedAt': surveyCompletedAt.toIso8601String(),
    };
    if (startLat != null) json['startLat'] = startLat;
    if (startLng != null) json['startLng'] = startLng;
    if (endLat != null) json['endLat'] = endLat;
    if (endLng != null) json['endLng'] = endLng;
    return json;
  }

  /// Full JSON for local storage (includes id and isSynced).
  Map<String, dynamic> toJson() => {
        'id': id,
        'tripStartTime': tripStartTime.toIso8601String(),
        'tripEndTime': tripEndTime.toIso8601String(),
        'tripPurpose': tripPurpose,
        'modeOfTransport': modeOfTransport,
        'numberOfPassengers': numberOfPassengers,
        'surveyCompletedAt': surveyCompletedAt.toIso8601String(),
        'startLat': startLat,
        'startLng': startLng,
        'endLat': endLat,
        'endLng': endLng,
        'isSynced': isSynced,
      };

  factory TripSurveyModel.fromJson(Map<String, dynamic> json) =>
      TripSurveyModel(
        id: json['id'] as String,
        tripStartTime: DateTime.parse(json['tripStartTime'] as String),
        tripEndTime: DateTime.parse(json['tripEndTime'] as String),
        tripPurpose: json['tripPurpose'] as String,
        modeOfTransport: json['modeOfTransport'] as String,
        numberOfPassengers: json['numberOfPassengers'] as int,
        surveyCompletedAt:
            DateTime.parse(json['surveyCompletedAt'] as String),
        startLat: (json['startLat'] as num?)?.toDouble(),
        startLng: (json['startLng'] as num?)?.toDouble(),
        endLat: (json['endLat'] as num?)?.toDouble(),
        endLng: (json['endLng'] as num?)?.toDouble(),
        isSynced: json['isSynced'] as bool? ?? false,
      );
}
