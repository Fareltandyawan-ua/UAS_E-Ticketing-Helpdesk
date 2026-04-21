import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/ticket_model.dart';
import '../data/ticket_api.dart';
import 'ticket_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../routes/app_routes.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late TicketController _ctrl;
  late AuthController _authCtrl;
  late String _ticketId;

  // Local comment controller — tidak ikut lifecycle GetX controller
  final TextEditingController _commentCtrl = TextEditingController();
  final RxBool _isSubmitting = false.obs;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<TicketController>();
    _authCtrl = Get.find<AuthController>();
    _ticketId = Get.arguments as String;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.loadTicketDetail(_ticketId);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _isSubmitting.value = true;
    try {
      final api = TicketApi();
      final comment = await api.addComment(_ticketId, text);
      _commentCtrl.clear();
      if (_ctrl.selectedTicket.value != null) {
        final t = _ctrl.selectedTicket.value!;
        _ctrl.selectedTicket.value = TicketModel(
          id: t.id,
          title: t.title,
          description: t.description,
          status: t.status,
          priority: t.priority,
          category: t.category,
          createdBy: t.createdBy,
          assignedTo: t.assignedTo,
          attachments: t.attachments,
          comments: [...t.comments, comment],
          createdAt: t.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isSubmitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tiket'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline_rounded),
            tooltip: 'Lihat Tracking',
            onPressed: () =>
                Get.toNamed(AppRoutes.tracking, arguments: _ticketId),
          ),
          Obx(() {
            if (!_authCtrl.isHelpdesk) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'status') {
                  _showUpdateStatusSheet(context);
                } else if (value == 'assign') {
                  _showAssignSheet(context);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'status',
                  child: Row(
                    children: [
                      Icon(Icons.sync_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Update Status'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'assign',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_outlined, size: 18),
                      SizedBox(width: 12),
                      Text('Assign Tiket'),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoadingDetail.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final ticket = _ctrl.selectedTicket.value;
        if (ticket == null) {
          return const EmptyState(
            title: 'Tiket tidak ditemukan',
            icon: Icons.error_outline,
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(context, ticket),
                    const SizedBox(height: 16),

                    _buildSection(
                      context,
                      title: 'Deskripsi',
                      child: Text(
                        ticket.description,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (ticket.attachments.isNotEmpty) ...[
                      _buildSection(
                        context,
                        title: 'Lampiran (${ticket.attachments.length})',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ticket.attachments
                              .map((url) => _AttachmentPreview(url: url))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Obx(() {
                      if (_ctrl.trackingList.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _buildSection(
                            context,
                            title: 'Riwayat Status',
                            trailing: TextButton.icon(
                              onPressed: () => Get.toNamed(
                                AppRoutes.tracking,
                                arguments: _ticketId,
                              ),
                              icon: const Icon(Icons.timeline_rounded, size: 14),
                              label: const Text('Lihat Semua'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                              ),
                            ),
                            child: Column(
                              children: _ctrl.trackingList
                                  .take(3)
                                  .map((t) => _TrackingTile(tracking: t))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),

                    _buildSection(
                      context,
                      title: 'Komentar (${ticket.comments.length})',
                      child: ticket.comments.isEmpty
                          ? Text(
                              'Belum ada komentar.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey400,
                              ),
                            )
                          : Column(
                              children: ticket.comments
                                  .map((c) => _CommentTile(comment: c))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _buildCommentInput(context),
          ],
        );
      }),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${ticket.id}',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.grey400),
              ),
              const Spacer(),
              StatusBadge(status: ticket.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(ticket.title, style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          _InfoRow(
              icon: Icons.category_outlined,
              label: 'Kategori',
              value: ticket.category),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Prioritas',
            value: '',
            widget: PriorityBadge(priority: ticket.priority),
          ),
          const SizedBox(height: 6),
          _InfoRow(
              icon: Icons.person_outline,
              label: 'Dibuat oleh',
              value: ticket.createdBy?.name ?? '-'),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.support_agent_outlined,
            label: 'Ditangani oleh',
            value: ticket.assignedTo?.name ?? 'Belum di-assign',
            valueColor:
                ticket.assignedTo == null ? AppColors.grey400 : null,
          ),
          const SizedBox(height: 6),
          _InfoRow(
              icon: Icons.access_time_outlined,
              label: 'Dibuat',
              value: DateFormatter.formatWithTime(ticket.createdAt)),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.titleMedium),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(
                hintText: 'Tulis komentar...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 10),
          Obx(
            () => _isSubmitting.value
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filled(
                    onPressed: _submitComment,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Status Tiket', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            ...['open', 'in_progress', 'resolved', 'closed'].map(
              (s) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _ctrl.updateStatus(_ticketId, s);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      StatusBadge(status: s),
                      const SizedBox(width: 12),
                      Text(
                        s.replaceAll('_', ' ').toUpperCase(),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignSheet(BuildContext context) {
    _ctrl.loadHelpdeskUsers();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Assign Tiket ke Helpdesk',
                  style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Pilih petugas yang akan menangani tiket ini',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (_ctrl.isLoadingHelpdeskUsers.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_ctrl.helpdeskUsers.isEmpty) {
                    return const EmptyState(
                      title: 'Tidak ada petugas helpdesk',
                      icon: Icons.people_outline,
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    itemCount: _ctrl.helpdeskUsers.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (_, i) {
                      final user = _ctrl.helpdeskUsers[i];
                      final isCurrentAssignee =
                          _ctrl.selectedTicket.value?.assignedTo?.id ==
                              user.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(user.name,
                            style: AppTextStyles.titleSmall),
                        subtitle: Text(
                          user.role == 'admin' ? 'Admin' : 'Helpdesk',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.grey400),
                        ),
                        trailing: isCurrentAssignee
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _ctrl.assignTicket(_ticketId, user.id);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── InfoRow ───────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? widget;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.widget,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.grey400),
        const SizedBox(width: 6),
        Text('$label: ',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
        Flexible(
          child: widget ??
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
        ),
      ],
    );
  }
}

// ── AttachmentPreview ─────────────────────────────────────────────────────────
class _AttachmentPreview extends StatelessWidget {
  final String url;
  const _AttachmentPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.snackbar('Lampiran', url,
          snackPosition: SnackPosition.BOTTOM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 80,
            height: 80,
            color: AppColors.grey100,
            child: const Icon(Icons.insert_drive_file_outlined,
                color: AppColors.grey400),
          ),
        ),
      ),
    );
  }
}

// ── CommentTile ───────────────────────────────────────────────────────────────
class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              comment.author?.name.isNotEmpty == true
                  ? comment.author!.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.author?.name ?? 'User',
                        style: AppTextStyles.titleSmall),
                    const Spacer(),
                    Text(
                      DateFormatter.timeAgo(comment.createdAt),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.grey400),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── TrackingTile ──────────────────────────────────────────────────────────────
class _TrackingTile extends StatelessWidget {
  final TicketTrackingModel tracking;
  const _TrackingTile({required this.tracking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 30, color: AppColors.borderLight),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(status: tracking.status),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatWithTime(tracking.createdAt),
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey400),
                ),
                if (tracking.description.isNotEmpty)
                  Text(
                    tracking.description,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
