import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/permission_service.dart';
import '../../../../core/services/background_location_service.dart';

/// State for the trip tracking feature.
class TripTrackingState {
  final bool permissionsGranted;
  final Map<String, bool> permissionStatus;
  final bool serviceRunning;
  final double currentSpeed;
  final bool isTripActive;
  final double gpsAccuracy;
  final bool isCoolingDown;
  final double cooldownProgress;

  const TripTrackingState({
    this.permissionsGranted = false,
    this.permissionStatus = const {},
    this.serviceRunning = false,
    this.currentSpeed = 0.0,
    this.isTripActive = false,
    this.gpsAccuracy = 0.0,
    this.isCoolingDown = false,
    this.cooldownProgress = 0.0,
  });

  TripTrackingState copyWith({
    bool? permissionsGranted,
    Map<String, bool>? permissionStatus,
    bool? serviceRunning,
    double? currentSpeed,
    bool? isTripActive,
    double? gpsAccuracy,
    bool? isCoolingDown,
    double? cooldownProgress,
  }) {
    return TripTrackingState(
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      serviceRunning: serviceRunning ?? this.serviceRunning,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      isTripActive: isTripActive ?? this.isTripActive,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      isCoolingDown: isCoolingDown ?? this.isCoolingDown,
      cooldownProgress: cooldownProgress ?? this.cooldownProgress,
    );
  }
}

/// Notifier that manages trip tracking state.
class TripTrackingNotifier extends StateNotifier<TripTrackingState> {
  TripTrackingNotifier() : super(const TripTrackingState()) {
    _init();
  }

  void _init() {
    checkPermissions();
    _listenToLocationUpdates();
  }

  Future<void> checkPermissions() async {
    final status = await PermissionService.checkPermissions();
    final allGranted = status.values.every((granted) => granted);
    state = state.copyWith(
      permissionStatus: status,
      permissionsGranted: allGranted,
    );
  }

  Future<void> requestPermissions() async {
    final granted = await PermissionService.requestAllPermissions();
    await checkPermissions();
    if (granted) {
      state = state.copyWith(permissionsGranted: true);
    }
  }

  Future<void> toggleService() async {
    if (state.serviceRunning) {
      await BackgroundLocationService.stopService();
    } else {
      await BackgroundLocationService.startService();
    }
    state = state.copyWith(serviceRunning: !state.serviceRunning);
  }

  void _listenToLocationUpdates() {
    BackgroundLocationService.updates.listen((data) {
      if (data != null) {
        state = state.copyWith(
          currentSpeed: (data['speedKmh'] as num).toDouble(),
          isTripActive: data['isTripActive'] as bool,
          gpsAccuracy: (data['accuracy'] as num?)?.toDouble() ?? 0.0,
          isCoolingDown: data['isCoolingDown'] as bool? ?? false,
          cooldownProgress: (data['cooldownProgress'] as num?)?.toDouble() ?? 0.0,
        );
      }
    });
  }
}

/// Global provider for trip tracking state.
final tripTrackingProvider =
    StateNotifierProvider<TripTrackingNotifier, TripTrackingState>(
  (ref) => TripTrackingNotifier(),
);
