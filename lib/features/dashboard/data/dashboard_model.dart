class DashboardStats {
  final int total;
  final int open;
  final int inProgress;
  final int assigned;
  final int closed;
  // Khusus Helpdesk/Admin
  final int assignedToMe;
  final int unassigned;

  DashboardStats({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.assigned,
    required this.closed,
    this.assignedToMe = 0,
    this.unassigned = 0,
  });

  factory DashboardStats.empty() => DashboardStats(
        total: 0,
        open: 0,
        inProgress: 0,
        assigned: 0,
        closed: 0,
        assignedToMe: 0,
        unassigned: 0,
      );
}
