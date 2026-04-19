// ─────────────────────────────────────────────
// dashboard_model.dart
// ─────────────────────────────────────────────
class DashboardStats {
  final int total;
  final int open;
  final int inProgress;
  final int resolved;
  final int closed;

  DashboardStats({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.resolved,
    required this.closed,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      total: json['total'] ?? 0,
      open: json['open'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      resolved: json['resolved'] ?? 0,
      closed: json['closed'] ?? 0,
    );
  }

  factory DashboardStats.empty() => DashboardStats(
        total: 0, open: 0, inProgress: 0, resolved: 0, closed: 0);
}
