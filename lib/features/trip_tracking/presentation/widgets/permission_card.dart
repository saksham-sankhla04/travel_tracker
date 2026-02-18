import 'package:flutter/material.dart';

class PermissionCard extends StatelessWidget {
  final Map<String, bool> permissionStatus;
  final bool permissionsGranted;
  final VoidCallback onRequestPermissions;
  final VoidCallback onOpenSettings;

  const PermissionCard({
    super.key,
    required this.permissionStatus,
    required this.permissionsGranted,
    required this.onRequestPermissions,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permissions',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _permissionRow(
                'Location', permissionStatus['location'] ?? false),
            _permissionRow('Background Location',
                permissionStatus['locationAlways'] ?? false),
            _permissionRow(
                'Notifications', permissionStatus['notification'] ?? false),
            const SizedBox(height: 12),
            if (!permissionsGranted)
              ElevatedButton.icon(
                onPressed: onRequestPermissions,
                icon: const Icon(Icons.security),
                label: const Text('Grant Permissions'),
              ),
            if (!permissionsGranted)
              TextButton(
                onPressed: onOpenSettings,
                child: const Text('Open App Settings'),
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
