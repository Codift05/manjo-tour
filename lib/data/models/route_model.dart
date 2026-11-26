import 'package:flutter/foundation.dart';
import '../../core/widgets/scenic_illustrations.dart';

enum RouteCategory {
  all('Semua'),
  mountain('Pegunungan'),
  coast('Pantai'),
  intercity('Lintas Kota'),
  camping('Camping');

  const RouteCategory(this.label);
  final String label;
}

@immutable
class RouteCheckpoint {
  const RouteCheckpoint({
    required this.name,
    required this.kmMark,
    required this.type,
    required this.note,
    this.completed = false,
  });

  final String name;
  final double kmMark;
  final String type;
  final String note;
  final bool completed;

  RouteCheckpoint copyWith({bool? completed}) {
    return RouteCheckpoint(
      name: name,
      kmMark: kmMark,
      type: type,
      note: note,
      completed: completed ?? this.completed,
    );
  }
}

@immutable
class TouringRoute {
  const TouringRoute({
    required this.id,
    required this.title,
    required this.region,
    required this.category,
    required this.distanceKm,
    required this.durationMinutes,
    required this.meetingPoint,
    required this.elevationGainM,
    required this.weatherSummary,
    required this.temperatureC,
    required this.description,
    required this.scenicVariant,
    required this.checkpoints,
    required this.offlineSizeMb,
    required this.convoyCode,
    this.isDownloaded = false,
    this.isBookmarked = false,
  });

  final String id;
  final String title;
  final String region;
  final RouteCategory category;
  final double distanceKm;
  final int durationMinutes;
  final String meetingPoint;
  final int elevationGainM;
  final String weatherSummary;
  final int temperatureC;
  final String description;
  final ScenicVariant scenicVariant;
  final List<RouteCheckpoint> checkpoints;
  final double offlineSizeMb;
  final String convoyCode;
  final bool isDownloaded;
  final bool isBookmarked;

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '$hours jam';
    return '${hours}j ${mins}m';
  }

  TouringRoute copyWith({
    bool? isDownloaded,
    bool? isBookmarked,
  }) {
    return TouringRoute(
      id: id,
      title: title,
      region: region,
      category: category,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      meetingPoint: meetingPoint,
      elevationGainM: elevationGainM,
      weatherSummary: weatherSummary,
      temperatureC: temperatureC,
      description: description,
      scenicVariant: scenicVariant,
      checkpoints: checkpoints,
      offlineSizeMb: offlineSizeMb,
      convoyCode: convoyCode,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
