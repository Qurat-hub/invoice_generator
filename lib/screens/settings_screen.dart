import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _settingsService = SettingsService.instance;

  late TextEditingController _companyNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _prefixCtrl;

  AppSettings _settings = AppSettings();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _settingsService.loadSettings();
    _companyNameCtrl = TextEditingController(text: settings.business.companyName);
    _addressCtrl = TextEditingController(text: settings.business.address);
    _emailCtrl = TextEditingController(text: settings.business.email);
    _phoneCtrl = TextEditingController(text: settings.business.phone);
    _taxCtrl = TextEditingController(text: settings.defaultTaxPercent.toString());
    _prefixCtrl = TextEditingController(text: settings.invoicePrefix);
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  /// Picks an image and stores it as base64 text. This is what makes
  /// the logo portable across Web (no filesystem), Android, and iOS —
  /// `XFile.readAsBytes()` works identically on every platform, unlike
  /// `File(path)` which only exists on native platforms.
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final Uint8List bytes = await picked.readAsBytes();
    final base64Str = base64Encode(bytes);
    setState(() {
      _settings = _settings.copyWith(
        business: _settings.business.copyWith(logoBase64: base64Str),
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final updated = _settings.copyWith(
      business: _settings.business.copyWith(
        companyName: _companyNameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      ),
      defaultTaxPercent: double.tryParse(_taxCtrl.text) ?? 0,
      invoicePrefix: _prefixCtrl.text.trim().isEmpty ? 'INV-' : _prefixCtrl.text.trim(),
    );
    await _settingsService.saveSettings(updated);
    if (!mounted) return;
    setState(() {
      _settings = updated;
      _saving = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _taxCtrl.dispose();
    _prefixCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasLogo = _settings.business.logoBase64.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _sectionCard(
              title: 'Company Logo',
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickLogo,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: hasLogo
                          ? MemoryImage(base64Decode(_settings.business.logoBase64))
                          : null,
                      child: !hasLogo
                          ? const Icon(Icons.add_a_photo_outlined,
                              color: AppColors.primary, size: 28)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _pickLogo,
                    child: Text(hasLogo ? 'Change Logo' : 'Upload Logo'),
                  ),
                ),
              ],
            ),
            _sectionCard(
              title: 'Company Details',
              children: [
                _textField(_companyNameCtrl, 'Company Name',
                    validator: (v) => Validators.required(v, field: 'Company name')),
                _textField(_addressCtrl, 'Address'),
                _textField(_emailCtrl, 'Email', validator: Validators.email),
                _textField(_phoneCtrl, 'Phone Number', validator: Validators.phone),
              ],
            ),
            _sectionCard(
              title: 'Invoice Preferences',
              children: [
                DropdownButtonFormField<String>(
                  value: kCurrencyOptions.contains(_settings.currencySymbol)
                      ? _settings.currencySymbol
                      : kCurrencyOptions.first,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: kCurrencyOptions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _settings = _settings.copyWith(currencySymbol: v));
                    }
                  },
                ),
                const SizedBox(height: 12),
                _textField(_taxCtrl, 'Default Tax Percentage (%)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => Validators.nonNegativeNumber(v, field: 'Tax')),
                _textField(_prefixCtrl, 'Invoice Prefix (e.g. INV-)',
                    validator: (v) => Validators.required(v, field: 'Prefix')),
              ],
            ),
            _sectionCard(
              title: 'Appearance',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Restart may be needed for full effect'),
                  value: _settings.darkMode,
                  onChanged: (v) async {
                    final updated = _settings.copyWith(darkMode: v);
                    await _settingsService.saveSettings(updated);
                    setState(() => _settings = updated);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label,
      {String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        keyboardType: keyboardType,
      ),
    );
  }
}
