import 'package:flutter/material.dart';

import 'services/permission_service.dart';
import 'services/notification_service.dart';
import 'services/background_location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await BackgroundLocationService.initialize();
  runApp(const TravelTrackerApp());
}

class TravelTrackerApp extends StatelessWidget {
  const TravelTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _permissionsGranted = false;
  bool _serviceRunning = false;
  Map<String, bool> _permissionStatus = {};
  double _currentSpeed = 0.0;
  bool _isTripActive = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _listenToLocationUpdates();
  }

  Future<void> _checkPermissions() async {
    final status = await PermissionService.checkPermissions();
    setState(() {
      _permissionStatus = status;
      _permissionsGranted = status.values.every((granted) => granted);
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await PermissionService.requestAllPermissions();
    await _checkPermissions();
    if (granted) {
      setState(() => _permissionsGranted = true);
    }
  }

  Future<void> _toggleService() async {
    if (_serviceRunning) {
      await BackgroundLocationService.stopService();
    } else {
      await BackgroundLocationService.startService();
    }
    setState(() => _serviceRunning = !_serviceRunning);
  }

  void _listenToLocationUpdates() {
    BackgroundLocationService.updates.listen((data) {
      if (data != null && mounted) {
        setState(() {
          _currentSpeed = (data['speedKmh'] as num).toDouble();
          _isTripActive = data['isTripActive'] as bool;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permission status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permissions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _permissionRow(
                        'Location', _permissionStatus['location'] ?? false),
                    _permissionRow('Background Location',
                        _permissionStatus['locationAlways'] ?? false),
                    _permissionRow('Notifications',
                        _permissionStatus['notification'] ?? false),
                    const SizedBox(height: 12),
                    if (!_permissionsGranted)
                      ElevatedButton.icon(
                        onPressed: _requestPermissions,
                        icon: const Icon(Icons.security),
                        label: const Text('Grant Permissions'),
                      ),
                    if (!_permissionsGranted)
                      TextButton(
                        onPressed: PermissionService.openSettings,
                        child: const Text('Open App Settings'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tracking control card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Tracking',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _serviceRunning
                              ? Icons.circle
                              : Icons.circle_outlined,
                          color:
                              _serviceRunning ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(_serviceRunning
                            ? 'Service running'
                            : 'Service stopped'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _permissionsGranted ? _toggleService : null,
                      icon: Icon(
                          _serviceRunning ? Icons.stop : Icons.play_arrow),
                      label:
                          Text(_serviceRunning ? 'Stop Tracking' : 'Start Tracking'),
                    ),
                    if (!_permissionsGranted)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Grant all permissions first to start tracking.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live data card
            if (_serviceRunning)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_currentSpeed.toStringAsFixed(1)} km/h',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                              color: _isTripActive
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isTripActive
                            ? 'Trip in progress'
                            : 'No trip detected',
                        style: TextStyle(
                          color:
                              _isTripActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _permissionRow(String name, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }
}
