import 'package:flutter/material.dart';
import '../../core/widgets/mascot_badge.dart';

@immutable
class DigitalPatch {
  const DigitalPatch({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.requirement,
    required this.progress,
    required this.unlocked,
    required this.pose,
    required this.patchAssetPath,
    required this.tintColor,
    required this.badgeIcon,
  });

  final String id;
  final String title;
  final String subtitle;
  final String requirement;
  final double progress;
  final bool unlocked;
  final MascotPose pose;
  final String patchAssetPath;
  final Color tintColor;
  final IconData badgeIcon;
}

@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.initials,
    required this.community,
    required this.totalKm,
    required this.rankDelta,
    required this.avatarColor,
    this.avatarAssetPath,
    this.isCurrentUser = false,
  });

  final int rank;
  final String name;
  final String initials;
  final String community;
  final int totalKm;
  final int rankDelta;
  final Color avatarColor;
  final String? avatarAssetPath;
  final bool isCurrentUser;
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
    this.unread = true,
  });

  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;
  final bool unread;

  AppNotification copyWith({bool? unread}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      timeLabel: timeLabel,
      icon: icon,
      unread: unread ?? this.unread,
    );
  }
}

@immutable
class RiderProfile {
  const RiderProfile({
    required this.name,
    required this.handle,
    required this.initials,
    required this.bikeModel,
    required this.level,
    required this.levelTitle,
    required this.levelProgress,
    required this.totalKm,
    required this.completedTrips,
    required this.zeroGapStreak,
    this.avatarAssetPath,
  });

  final String name;
  final String handle;
  final String initials;
  final String bikeModel;
  final int level;
  final String levelTitle;
  final double levelProgress;
  final int totalKm;
  final int completedTrips;
  final int zeroGapStreak;
  final String? avatarAssetPath;
}
