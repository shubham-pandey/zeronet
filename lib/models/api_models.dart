import 'dart:convert';

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromMap(Map<String, dynamic> map) {
    return AuthResponse(
      token: map['token']?.toString() ?? '',
      user: User.fromMap(map['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'user': user.toMap(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory AuthResponse.fromJson(String source) =>
      AuthResponse.fromMap(json.decode(source) as Map<String, dynamic>);
}

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? organizationId;
  final String role;
  final bool? verified;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.organizationId,
    required this.role,
    this.verified,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString(),
      organizationId: map['organizationId']?.toString(),
      role: map['role']?.toString() ?? 'viewer',
      verified: map['verified'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'organizationId': organizationId,
      'role': role,
      'verified': verified,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);
}

class Organization {
  final String id;
  final String orgName;
  final String? orgType;
  final String? registrationId;
  final String? address;
  final String? contactPerson;
  final bool? is24Hours;

  Organization({
    required this.id,
    required this.orgName,
    this.orgType,
    this.registrationId,
    this.address,
    this.contactPerson,
    this.is24Hours,
  });

  factory Organization.fromMap(Map<String, dynamic> map) {
    return Organization(
      id: map['id']?.toString() ?? '',
      orgName: map['orgName']?.toString() ?? '',
      orgType: map['orgType']?.toString(),
      registrationId: map['registrationId']?.toString(),
      address: map['address']?.toString(),
      contactPerson: map['contactPerson']?.toString(),
      is24Hours: map['is24Hours'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orgName': orgName,
      'orgType': orgType,
      'registrationId': registrationId,
      'address': address,
      'contactPerson': contactPerson,
      'is24Hours': is24Hours,
    };
  }
}

class OtpResponse {
  final String message;
  final int expiresIn;

  OtpResponse({
    required this.message,
    required this.expiresIn,
  });

  factory OtpResponse.fromMap(Map<String, dynamic> map) {
    return OtpResponse(
      message: map['message']?.toString() ?? '',
      expiresIn: (map['expiresIn'] as num?)?.toInt() ?? 30,
    );
  }
}
