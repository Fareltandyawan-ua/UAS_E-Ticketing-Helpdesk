import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/app_widgets.dart';
import '../ticket/presentation/ticket_controller.dart';
import '../ticket/presentation/ticket_list_screen.dart';

/// Riwayat tiket — menampilkan tiket yang sudah berstatus `closed`
/// untuk user yang sedang login. SRS FR-010.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TicketController _ctrl = Get.find<TicketController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Tiket'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoadingHistory.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctrl.historyList.isEmpty) {
          return const EmptyState(
            title: 'Belum ada riwayat',
            subtitle: 'Tiket yang sudah ditutup akan tampil di sini',
            icon: Icons.history_rounded,
          );
        }
        return RefreshIndicator(
          onRefresh: _ctrl.fetchHistory,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _ctrl.historyList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => TicketCard(ticket: _ctrl.historyList[i]),
          ),
        );
      }),
    );
  }
}
