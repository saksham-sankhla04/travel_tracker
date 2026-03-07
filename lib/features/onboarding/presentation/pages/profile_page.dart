import 'package:flutter/material.dart';

import '../../data/services/onboarding_storage_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _homeAddressController = TextEditingController();
  final _workSchoolController = TextEditingController();

  bool _addWorkSchoolAddress = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _homeAddressController.dispose();
    _workSchoolController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final home = await OnboardingStorageService.getHomeAddress() ?? '';
    final workSchool =
        await OnboardingStorageService.getWorkSchoolAddress() ?? '';
    if (!mounted) return;
    _homeAddressController.text = home;
    _workSchoolController.text = workSchool;
    setState(() {
      _addWorkSchoolAddress = workSchool.trim().isNotEmpty;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);
    await OnboardingStorageService.updateAddresses(
      homeAddress: _homeAddressController.text,
      workSchoolAddress: _addWorkSchoolAddress
          ? _workSchoolController.text
          : null,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Addresses updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      'Address Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _homeAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Home address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      minLines: 2,
                      maxLines: 3,
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
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        minLines: 2,
                        maxLines: 3,
                        validator: (value) {
                          if (_addWorkSchoolAddress &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter work/school address';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
