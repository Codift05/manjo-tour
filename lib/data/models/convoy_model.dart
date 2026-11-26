import 'package:flutter/material.dart';

enum RiderRole {
  leader('Leader'),
  sweeper('Sweeper'),
  you('You'),
  member('Rider');

  const RiderRole(this.label);
  final String label;
}

@immutable
class ConvoyMember {
  const ConvoyMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.bikeModel,
    required this.role,
    required this.avatarColor,
    required this.routeProgress,
    required this.lateralOffset,
    required this.speedKmh,
    required this.gapMeters,
    this.avatarAssetPath,
    this.isConnected = true,
    this.isSpeaking = false,
  });

  final String id;
  final String name;
  final String initials;
  final String bikeModel;
  final RiderRole role;
  final Color avatarColor;
  final String? avatarAssetPath;

  /// Normalized position along the simulated route path (0.0 start -> 1.0 finish).
  final double routeProgress;

  /// Small horizontal visual spread so avatars never stack directly on top of each other.
  final double lateralOffset;

  final int speedKmh;

  /// Distance in meters relative to the Sweeper / formation anchor.
  final int gapMeters;

  final bool isConnected;
  final bool isSpeaking;

  ConvoyMember copyWith({
    double? routeProgress,
    double? lateralOffset,
    int? speedKmh,
    int? gapMeters,
    bool? isConnected,
    bool? isSpeaking,
  }) {
    return ConvoyMember(
      id: id,
      name: name,
      initials: initials,
      bikeModel: bikeModel,
      role: role,
      avatarColor: avatarColor,
      avatarAssetPath: avatarAssetPath,
      routeProgress: routeProgress ?? this.routeProgress,
      lateralOffset: lateralOffset ?? this.lateralOffset,
      speedKmh: speedKmh ?? this.speedKmh,
      gapMeters: gapMeters ?? this.gapMeters,
      isConnected: isConnected ?? this.isConnected,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

enum HazardType {
  pothole(
    'Jalan Berlubang',
    'Lubang dalam di sisi kiri jalur',
    Icons.warning_amber_rounded,
    Color(0xFFC2410C),
  ),
  slippery(
    'Jalan Licin / Hujan',
    'Permukaan basah dan berkabut',
    Icons.water_drop_rounded,
    Color(0xFF0369A1),
  ),
  congestion(
    'Macet / Longsor',
    'Antrean kendaraan atau material jalan',
    Icons.traffic_rounded,
    Color(0xFFB91C1C),
  ),
  fuelTrouble(
    'Butuh Bensin / Trouble',
    'Anggota menepi untuk bensin atau cek motor',
    Icons.local_gas_station_rounded,
    Color(0xFF15803D),
  );

  const HazardType(this.label, this.shortNote, this.icon, this.color);

  final String label;
  final String shortNote;
  final IconData icon;
  final Color color;
}

@immutable
class HazardPin {
  const HazardPin({
    required this.id,
    required this.type,
    required this.reporterName,
    required this.routeProgress,
    required this.lateralOffset,
    required this.timeLabel,
    this.note,
  });

  final String id;
  final HazardType type;
  final String reporterName;
  final double routeProgress;
  final double lateralOffset;
  final String timeLabel;
  final String? note;
}
