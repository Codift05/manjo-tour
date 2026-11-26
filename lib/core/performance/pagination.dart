import 'package:flutter/foundation.dart';

/// Immutable pagination slice metadata used by Home Routes, Trips, and Leaderboard.
@immutable
class PaginatedSlice<T> {
  const PaginatedSlice({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.servedByNode,
    required this.fromCache,
    this.isLoadingMore = false,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final String servedByNode;
  final bool fromCache;
  final bool isLoadingMore;

  bool get hasMore => items.length < totalItems;

  PaginatedSlice<T> copyWith({
    List<T>? items,
    int? page,
    int? pageSize,
    int? totalItems,
    String? servedByNode,
    bool? fromCache,
    bool? isLoadingMore,
  }) {
    return PaginatedSlice<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      servedByNode: servedByNode ?? this.servedByNode,
      fromCache: fromCache ?? this.fromCache,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
