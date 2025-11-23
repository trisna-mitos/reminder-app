import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk data SIM (Surat Izin Mengemudi)
class LicenseModel {
  final String id;
  final String licenseNumber;
  final String licenseType; // SIM A, SIM B, SIM C
  final String ownerName;
  final DateTime expirationDate;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LicenseModel({
    required this.id,
    required this.licenseNumber,
    required this.licenseType,
    required this.ownerName,
    required this.expirationDate,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert model ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'licenseNumber': licenseNumber,
      'licenseType': licenseType,
      'ownerName': ownerName,
      'expirationDate': Timestamp.fromDate(expirationDate),
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Convert Map dari Firestore ke model
  factory LicenseModel.fromMap(Map<String, dynamic> map, String documentId) {
    return LicenseModel(
      id: documentId,
      licenseNumber: map['licenseNumber'] ?? '',
      licenseType: map['licenseType'] ?? '',
      ownerName: map['ownerName'] ?? '',
      expirationDate: (map['expirationDate'] as Timestamp).toDate(),
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert model ke JSON untuk local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licenseNumber': licenseNumber,
      'licenseType': licenseType,
      'ownerName': ownerName,
      'expirationDate': expirationDate.toIso8601String(),
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Convert JSON dari local storage ke model
  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    return LicenseModel(
      id: json['id'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      licenseType: json['licenseType'] ?? '',
      ownerName: json['ownerName'] ?? '',
      expirationDate: DateTime.parse(json['expirationDate']),
      photoUrl: json['photoUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  /// Hitung jumlah hari sampai kadaluarsa
  int get daysUntilExpiration {
    final now = DateTime.now();
    final difference = expirationDate.difference(now);
    return difference.inDays;
  }

  /// Check apakah sudah kadaluarsa
  bool get isExpired {
    return DateTime.now().isAfter(expirationDate);
  }

  /// Check apakah dalam 7 hari akan kadaluarsa
  bool get isExpiringSoon {
    return daysUntilExpiration <= 7 && daysUntilExpiration >= 0;
  }

  /// Copy dengan beberapa field yang diubah
  LicenseModel copyWith({
    String? id,
    String? licenseNumber,
    String? licenseType,
    String? ownerName,
    DateTime? expirationDate,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LicenseModel(
      id: id ?? this.id,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseType: licenseType ?? this.licenseType,
      ownerName: ownerName ?? this.ownerName,
      expirationDate: expirationDate ?? this.expirationDate,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LicenseModel(id: $id, licenseNumber: $licenseNumber, licenseType: $licenseType, ownerName: $ownerName, expirationDate: $expirationDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LicenseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
