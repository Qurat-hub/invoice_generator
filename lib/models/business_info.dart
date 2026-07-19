/// Represents the company/business issuing the invoice.
/// A snapshot of this is stored on each invoice so historical invoices
/// remain accurate even if the company settings change later.
///
/// The logo is stored as a base64-encoded string (`logoBase64`) rather
/// than a file path. This is what makes it portable across platforms:
/// on Web there is no filesystem to point a path at, but a base64
/// string can be persisted (Hive/SharedPreferences) and rendered with
/// `Image.memory` / `pw.MemoryImage` on every platform identically.
class BusinessInfo {
  String companyName;
  String address;
  String email;
  String phone;
  String logoBase64; // Base64-encoded logo image bytes, empty if none.

  BusinessInfo({
    this.companyName = '',
    this.address = '',
    this.email = '',
    this.phone = '',
    this.logoBase64 = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'address': address,
      'email': email,
      'phone': phone,
      'logoBase64': logoBase64,
    };
  }

  factory BusinessInfo.fromJson(Map<String, dynamic> json) {
    return BusinessInfo(
      companyName: json['companyName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      logoBase64: json['logoBase64'] as String? ?? '',
    );
  }

  BusinessInfo copyWith({
    String? companyName,
    String? address,
    String? email,
    String? phone,
    String? logoBase64,
  }) {
    return BusinessInfo(
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      logoBase64: logoBase64 ?? this.logoBase64,
    );
  }
}
