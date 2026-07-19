import 'business_info.dart';

/// Global, persisted app configuration (Settings screen).
/// Stored via SharedPreferences, which — unlike sqflite — already works
/// natively on Web (backed by localStorage), Android, and iOS.
class AppSettings {
  BusinessInfo business;
  String currencySymbol;
  double defaultTaxPercent;
  String invoicePrefix;
  bool darkMode;
  int lastInvoiceNumber;

  AppSettings({
    BusinessInfo? business,
    this.currencySymbol = '\$',
    this.defaultTaxPercent = 0,
    this.invoicePrefix = 'INV-',
    this.darkMode = false,
    this.lastInvoiceNumber = 0,
  }) : business = business ?? BusinessInfo();

  /// Generates the next unique invoice number, e.g. INV-001, INV-002 ...
  String get nextInvoiceNumber {
    final next = lastInvoiceNumber + 1;
    return '$invoicePrefix${next.toString().padLeft(3, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': business.companyName,
      'address': business.address,
      'email': business.email,
      'phone': business.phone,
      'logoBase64': business.logoBase64,
      'currencySymbol': currencySymbol,
      'defaultTaxPercent': defaultTaxPercent,
      'invoicePrefix': invoicePrefix,
      'darkMode': darkMode,
      'lastInvoiceNumber': lastInvoiceNumber,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      business: BusinessInfo(
        companyName: json['companyName'] as String? ?? '',
        address: json['address'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        logoBase64: json['logoBase64'] as String? ?? '',
      ),
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
      defaultTaxPercent: (json['defaultTaxPercent'] as num?)?.toDouble() ?? 0,
      invoicePrefix: json['invoicePrefix'] as String? ?? 'INV-',
      darkMode: json['darkMode'] as bool? ?? false,
      lastInvoiceNumber: json['lastInvoiceNumber'] as int? ?? 0,
    );
  }

  AppSettings copyWith({
    BusinessInfo? business,
    String? currencySymbol,
    double? defaultTaxPercent,
    String? invoicePrefix,
    bool? darkMode,
    int? lastInvoiceNumber,
  }) {
    return AppSettings(
      business: business ?? this.business,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      defaultTaxPercent: defaultTaxPercent ?? this.defaultTaxPercent,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      darkMode: darkMode ?? this.darkMode,
      lastInvoiceNumber: lastInvoiceNumber ?? this.lastInvoiceNumber,
    );
  }
}
