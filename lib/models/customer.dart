class Customer {
  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  final String id;
  String name;
  String phone;
  final DateTime createdAt;

  Customer copyWith({String? name, String? phone}) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }
}
