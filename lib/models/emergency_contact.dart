class EmergencyContact {
  const EmergencyContact({
    this.id,
    required this.name,
    required this.relationship,
    required this.phone,
  });

  final String? id;
  final String name;
  final String relationship;
  final String phone;

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'relationship': relationship.trim(),
        'phone': phone.trim(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

  factory EmergencyContact.fromMap(String id, Map<String, dynamic> map) {
    return EmergencyContact(
      id: id,
      name: map['name'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }
}
