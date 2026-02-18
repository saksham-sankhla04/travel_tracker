import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Requests all permissions needed for trip tracking.
  /// Returns true only if all critical permissions are granted.
  static Future<bool> requestAllPermissions() async {
    // Step 1: Request fine location (foreground)
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) return false;

    // Step 2: Request "Always" (background) location
    // Android requires foreground location to be granted first
    final bgStatus = await Permission.locationAlways.request();
    if (!bgStatus.isGranted) return false;

    // Step 3: Request notification permission (Android 13+)
    final notifStatus = await Permission.notification.request();
    if (!notifStatus.isGranted) return false;

    return true;
  }

  /// Checks current status of all required permissions.
  static Future<Map<String, bool>> checkPermissions() async {
    return {
      'location': await Permission.location.isGranted,
      'locationAlways': await Permission.locationAlways.isGranted,
      'notification': await Permission.notification.isGranted,
    };
  }

  /// Opens app settings so the user can manually grant permissions.
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
