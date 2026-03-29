import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/maintenance_service.dart';
import '../../models/maintenance_model.dart';
import '../../widgets/empty_state.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  final MaintenanceService _maintenanceService = MaintenanceService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Fixed'),
          ],
        ),
        Expanded(
          child: StreamBuilder<List<MaintenanceModel>>(
            stream: _maintenanceService.getMaintenanceByLandlord(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allRequests = snapshot.data ?? [];

              if (allRequests.isEmpty) {
                return const EmptyState(
                  icon: Icons.build,
                  title: 'No Maintenance Requests',
                  subtitle: 'All maintenance requests will appear here',
                );
              }

              final pending = allRequests
                  .where((r) => r.status == MaintenanceStatus.pending)
                  .toList();
              final inProgress = allRequests
                  .where((r) => r.status == MaintenanceStatus.inProgress)
                  .toList();
              final fixed = allRequests
                  .where((r) => r.status == MaintenanceStatus.fixed)
                  .toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildMaintenanceList(pending, MaintenanceStatus.pending),
                  _buildMaintenanceList(inProgress, MaintenanceStatus.inProgress),
                  _buildMaintenanceList(fixed, MaintenanceStatus.fixed),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceList(
      List<MaintenanceModel> requests, MaintenanceStatus status) {
    if (requests.isEmpty) {
      String message;
      switch (status) {
        case MaintenanceStatus.pending:
          message = 'No pending requests';
          break;
        case MaintenanceStatus.inProgress:
          message = 'No requests in progress';
          break;
        case MaintenanceStatus.fixed:
          message = 'No fixed requests yet';
          break;
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildMaintenanceCard(request);
      },
    );
  }

  Widget _buildMaintenanceCard(MaintenanceModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPriorityIcon(request.priority),
                  color: _getPriorityColor(request.priority),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  request.tenantName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            if (request.status != MaintenanceStatus.fixed) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (request.status == MaintenanceStatus.pending)
                    OutlinedButton.icon(
                      onPressed: () => _updateStatus(
                        request.id,
                        MaintenanceStatus.inProgress,
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start'),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(
                      request.id,
                      MaintenanceStatus.fixed,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Mark Fixed'),
                  ),
                ],
              ),
            ],
            if (request.responseNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.comment, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.responseNote!,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(MaintenanceStatus status) {
    Color color;
    String text;
    switch (status) {
      case MaintenanceStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case MaintenanceStatus.inProgress:
        color = Colors.blue;
        text = 'In Progress';
        break;
      case MaintenanceStatus.fixed:
        color = Colors.green;
        text = 'Fixed';
        break;
    }

    return Chip(
      label: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  IconData _getPriorityIcon(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return Icons.arrow_downward;
      case MaintenancePriority.medium:
        return Icons.remove;
      case MaintenancePriority.high:
        return Icons.arrow_upward;
      case MaintenancePriority.urgent:
        return Icons.priority_high;
    }
  }

  Color _getPriorityColor(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return Colors.green;
      case MaintenancePriority.medium:
        return Colors.orange;
      case MaintenancePriority.high:
        return Colors.red;
      case MaintenancePriority.urgent:
        return Colors.red.shade900;
    }
  }

  Future<void> _updateStatus(String id, MaintenanceStatus status) async {
    final success = await _maintenanceService.updateMaintenanceStatus(id, status);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Status updated to ${status.name}'
                : 'Failed to update status',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}