/// Represents the customer/client the invoice is billed to.
class Customer {
  String name;
  String address;
  String email;
  String phone;

  Customer({
    this.name = '',
    this.address = '',
    this.email = '',
    this.phone = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'email': email,
      'phone': phone,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  Customer copyWith({
    String? name,
    String? address,
    String? email,
    String? phone,
  }) {
    return Customer(
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
