import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/permission_service.dart';
import '../../data/services/onboarding_storage_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const int _lastStep = 4;

  final _pageController = PageController();
  final _addressFormKey = GlobalKey<FormState>();
  final _homeAddressController = TextEditingController();
  final _workSchoolController = TextEditingController();

  int _currentStep = 0;
  bool _addWorkSchoolAddress = false;
  bool _isRequestingPermissions = false;
  bool _isSaving = false;
  Map<String, bool> _permissionStatus = const {
    'location': false,
    'locationAlways': false,
    'notification': false,
  };

  bool get _allPermissionsGranted =>
      _permissionStatus.values.every((granted) => granted);

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _homeAddressController.dispose();
    _workSchoolController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissionStatus() async {
    final status = await PermissionService.checkPermissions();
    if (!mounted) return;
    setState(() => _permissionStatus = status);
  }

  Future<void> _requestPermissions() async {
    setState(() => _isRequestingPermissions = true);
    await PermissionService.requestAllPermissions();
    await _loadPermissionStatus();
    if (!mounted) return;
    setState(() => _isRequestingPermissions = false);
  }

  Future<void> _goToStep(int step) async {
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    if (!mounted) return;
    setState(() => _currentStep = step);
  }

  Future<void> _next() async {
    if (_currentStep == 2 && !_allPermissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please grant all permissions to continue.'),
        ),
      );
      return;
    }

    if (_currentStep == 3) {
      if (!_addressFormKey.currentState!.validate()) return;
    }

    if (_currentStep < _lastStep) {
      await _goToStep(_currentStep + 1);
    }
  }

  Future<void> _back() async {
    if (_currentStep > 0) {
      await _goToStep(_currentStep - 1);
    }
  }

  Future<void> _finish() async {
    if (!_addressFormKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    await OnboardingStorageService.completeOnboarding(
      homeAddress: _homeAddressController.text,
      workSchoolAddress: _addWorkSchoolAddress
          ? _workSchoolController.text
          : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Setup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / (_lastStep + 1),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Step ${_currentStep + 1} of ${_lastStep + 1}'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildWelcomeStep(context),
                      _buildHowItWorksStep(context),
                      _buildPermissionStep(context),
                      _buildAddressStep(context),
                      _buildFinishStep(context),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: const Text('Back'),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox.shrink()),
                  const SizedBox(width: 10),
                  if (_currentStep < _lastStep)
                    Expanded(
                      child: FilledButton(
                        onPressed: _next,
                        child: const Text('Next'),
                      ),
                    )
                  else
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _finish,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isSaving ? 'Saving...' : 'Start App'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(BuildContext context) {
    return ListView(
      children: [
        _stepTitle(
          context,
          icon: Icons.waving_hand,
          title: 'Welcome to Travel Tracker',
        ),
        const SizedBox(height: 12),
        const Text(
          'This app detects trips in the background and helps collect mobility research data.',
        ),
        const SizedBox(height: 20),
        _infoTile(
          icon: Icons.route_outlined,
          title: 'Automatic detection',
          subtitle: 'Trips start/stop based on movement and speed.',
        ),
        _infoTile(
          icon: Icons.flag_outlined,
          title: 'Manual stop',
          subtitle: 'You can end an active trip manually anytime.',
        ),
        _infoTile(
          icon: Icons.cloud_upload_outlined,
          title: 'Reliable saving',
          subtitle: 'Trip route is saved even if survey is skipped.',
        ),
      ],
    );
  }

  Widget _buildHowItWorksStep(BuildContext context) {
    return ListView(
      children: [
        _stepTitle(
          context,
          icon: Icons.psychology_alt_outlined,
          title: 'How it works',
        ),
        const SizedBox(height: 16),
        const Text('1. Start tracking from the home screen.'),
        const SizedBox(height: 8),
        const Text('2. App detects when you are travelling.'),
        const SizedBox(height: 8),
        const Text('3. At trip end, route is auto-saved to backend.'),
        const SizedBox(height: 8),
        const Text(
          '4. You can submit survey details later to update that same trip.',
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If you skip the form, default values are used and can be corrected later.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionStep(BuildContext context) {
    return ListView(
      children: [
        _stepTitle(context, icon: Icons.shield_outlined, title: 'Permissions'),
        const SizedBox(height: 12),
        const Text(
          'Location and notification permissions are required for reliable trip tracking.',
        ),
        const SizedBox(height: 20),
        _permissionTile(
          label: 'Location',
          value: _permissionStatus['location'] ?? false,
        ),
        _permissionTile(
          label: 'Background location',
          value: _permissionStatus['locationAlways'] ?? false,
        ),
        _permissionTile(
          label: 'Notifications',
          value: _permissionStatus['notification'] ?? false,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _isRequestingPermissions ? null : _requestPermissions,
          icon: _isRequestingPermissions
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_open),
          label: Text(
            _isRequestingPermissions ? 'Requesting...' : 'Grant Permissions',
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: PermissionService.openSettings,
          child: const Text('Open app settings'),
        ),
      ],
    );
  }

  Widget _buildAddressStep(BuildContext context) {
    return Form(
      key: _addressFormKey,
      child: ListView(
        children: [
          _stepTitle(
            context,
            icon: Icons.location_city_outlined,
            title: 'Your addresses',
          ),
          const SizedBox(height: 12),
          const Text('Home address is required. Work/School is optional.'),
          const SizedBox(height: 20),
          TextFormField(
            controller: _homeAddressController,
            decoration: const InputDecoration(
              labelText: 'Home address',
              hintText: 'Enter your home address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home_outlined),
            ),
            minLines: 2,
            maxLines: 3,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Home address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add work/school address'),
            subtitle: const Text('Optional'),
            value: _addWorkSchoolAddress,
            onChanged: (value) {
              setState(() => _addWorkSchoolAddress = value);
              if (!value) _workSchoolController.clear();
            },
          ),
          if (_addWorkSchoolAddress) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _workSchoolController,
              decoration: const InputDecoration(
                labelText: 'Work/School address',
                hintText: 'Enter your work or school address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_outlined),
              ),
              minLines: 2,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (_addWorkSchoolAddress &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please enter work/school address or disable this option';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinishStep(BuildContext context) {
    return ListView(
      children: [
        _stepTitle(
          context,
          icon: Icons.verified_outlined,
          title: 'You are ready',
        ),
        const SizedBox(height: 12),
        _statusRow('Permissions granted', _allPermissionsGranted),
        _statusRow(
          'Home address added',
          _homeAddressController.text.trim().isNotEmpty,
        ),
        _statusRow(
          'Work/School address',
          !_addWorkSchoolAddress ||
              _workSchoolController.text.trim().isNotEmpty,
        ),
        const SizedBox(height: 20),
        const Text(
          'Tap "Start App" to finish onboarding and open the tracker dashboard.',
        ),
      ],
    );
  }

  Widget _permissionTile({required String label, required bool value}) {
    return Card(
      child: ListTile(
        leading: Icon(
          value ? Icons.check_circle : Icons.error_outline,
          color: value ? Colors.green : Colors.orange,
        ),
        title: Text(label),
        trailing: Text(value ? 'Granted' : 'Required'),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _statusRow(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            color: ok ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _stepTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}
