import 'package:flutter/material.dart';
import '../../core/widgets/scenic_illustrations.dart';
import 'route_model.dart';

enum TripStatus {
  active('Aktif'),
  upcoming('Terjadwal'),
  completed('Selesai');

  const TripStatus(this.label);
  final String label;
}

enum ExpenseCategory {
  fuel('Bensin', Icons.local_gas_station_rounded, Color(0xFF15803D)),
  food('Makan Bersama', Icons.restaurant_rounded, Color(0xFFC2410C)),
  lodging('Penginapan', Icons.cabin_rounded, Color(0xFF0F766E)),
  other('Logistik Lain', Icons.backpack_rounded, Color(0xFF475569));

  const ExpenseCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class TripParticipant {
  const TripParticipant({
    required this.id,
    required this.name,
    required this.initials,
    required this.roleLabel,
    required this.bikeModel,
    required this.avatarColor,
    this.avatarAssetPath,
  });

  final String id;
  final String name;
  final String initials;
  final String roleLabel;
  final String bikeModel;
  final Color avatarColor;
  final String? avatarAssetPath;
}

@immutable
class TripExpense {
  const TripExpense({
    required this.id,
    required this.title,
    required this.category,
    required this.amountIdr,
    required this.paidById,
    required this.timeLabel,
    required this.paidStatusByMemberId,
  });

  final String id;
  final String title;
  final ExpenseCategory category;
  final int amountIdr;
  final String paidById;
  final String timeLabel;

  /// Maps each participantId -> true (Lunas) or false (Belum Bayar).
  final Map<String, bool> paidStatusByMemberId;

  int get perMemberShare {
    if (paidStatusByMemberId.isEmpty) return amountIdr;
    return (amountIdr / paidStatusByMemberId.length).round();
  }

  int get settledCount =>
      paidStatusByMemberId.values.where((paid) => paid).length;

  TripExpense toggleMemberPaid(String memberId) {
    final next = Map<String, bool>.from(paidStatusByMemberId);
    next[memberId] = !(next[memberId] ?? false);
    return TripExpense(
      id: id,
      title: title,
      category: category,
      amountIdr: amountIdr,
      paidById: paidById,
      timeLabel: timeLabel,
      paidStatusByMemberId: next,
    );
  }
}

@immutable
class TouringTrip {
  const TouringTrip({
    required this.id,
    required this.title,
    required this.routeId,
    required this.region,
    required this.dateLabel,
    required this.distanceKm,
    required this.status,
    required this.scenicVariant,
    required this.convoyCode,
    required this.participants,
    required this.checkpoints,
    required this.expenses,
  });

  final String id;
  final String title;
  final String routeId;
  final String region;
  final String dateLabel;
  final double distanceKm;
  final TripStatus status;
  final ScenicVariant scenicVariant;
  final String convoyCode;
  final List<TripParticipant> participants;
  final List<RouteCheckpoint> checkpoints;
  final List<TripExpense> expenses;

  int get totalExpenseIdr =>
      expenses.fold<int>(0, (sum, e) => sum + e.amountIdr);

  int get perRiderTotalIdr {
    if (participants.isEmpty) return 0;
    return (totalExpenseIdr / participants.length).round();
  }

  TouringTrip copyWith({
    List<TripExpense>? expenses,
    List<RouteCheckpoint>? checkpoints,
  }) {
    return TouringTrip(
      id: id,
      title: title,
      routeId: routeId,
      region: region,
      dateLabel: dateLabel,
      distanceKm: distanceKm,
      status: status,
      scenicVariant: scenicVariant,
      convoyCode: convoyCode,
      participants: participants,
      checkpoints: checkpoints ?? this.checkpoints,
      expenses: expenses ?? this.expenses,
    );
  }
}
