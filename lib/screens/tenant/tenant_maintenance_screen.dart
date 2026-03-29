import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/maintenance_service.dart';
import '../../models/maintenance_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_text_field.dart';

class TenantMaintenanceScreen extends StatefulWidget {
  const TenantMaintenanceScreen({super.key});

  @override
  State<TenantMaintenanceScreen> createState() => _TenantMaintenanceScreenState();
}

class _TenantMaintenanceScreenState extends State<TenantMaintenanceScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Scaffold(
      body: StreamBuilder<List<MaintenanceModel>>(
        stream: _maintenanceService.getMaintenanceByTenant(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return EmptyState(
              icon: Icons.build,
              title: 'No Maintenance Requests',
              subtitle: 'Submit a request when something needs fixing',
              buttonText: 'New Request',
              onButtonPressed: () => _showNewRequestDialog(context, user),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(request);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewRequestDialog(context, user),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildRequestCard(MaintenanceModel request) {
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
            const SizedBox(height: 12),
            Text(
              request.description,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Submitted: ${_formatDate(request.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            if (request.responseNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.comment, size: 16, color: Colors.teal.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Response from Manager',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.responseNote!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
            if (request.status == MaintenanceStatus.fixed && request.fixedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Fixed on: ${_formatDate(request.fixedAt!)}',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
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
    IconData icon;

    switch (status) {
      case MaintenanceStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case MaintenanceStatus.inProgress:
        color = Colors.blue;
        text = 'In Progress';
        icon = Icons.engineering;
        break;
      case MaintenanceStatus.fixed:
        color = Colors.green;
        text = 'Fixed';
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showNewRequestDialog(BuildContext context, dynamic user) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    MaintenancePriority selectedPriority = MaintenancePriority.medium;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Maintenance Request'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: titleController,
                    label: 'Issue Title',
                    hint: 'e.g., Leaking tap in bathroom',
                    prefixIcon: Icons.title,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: descriptionController,
                    label: 'Description',
                    hint: 'Describe the issue in detail...',
                    prefixIcon: Icons.description,
                    maxLines: 4,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MaintenancePriority>(
                    initialValue: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items: MaintenancePriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Icon(
                              _getPriorityIcon(priority),
                              color: _getPriorityColor(priority),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(_getPriorityName(priority)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedPriority = value!);
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Use "Urgent" only for emergencies like flooding or electrical issues.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isSubmitting = true);

                      final request = MaintenanceModel(
                        id: '',
                        tenantId: user.uid,
                        tenantName: user.fullName,
                        landlordId: user.assignedLandlordId ?? '',
                        propertyId: user.assignedPropertyId ?? '',
                        unitId: user.assignedUnitId ?? '',
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        status: MaintenanceStatus.pending,
                        priority: selectedPriority,
                        createdAt: DateTime.now(),
                      );

                      final result = await _maintenanceService.createMaintenanceRequest(request);

                      setState(() => isSubmitting = false);

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result != null
                                  ? 'Request submitted successfully!'
                                  : 'Failed to submit request',
                            ),
                            backgroundColor: result != null ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriorityName(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return 'Low';
      case MaintenancePriority.medium:
        return 'Medium';
      case MaintenancePriority.high:
        return 'High';
      case MaintenancePriority.urgent:
        return 'Urgent';
    }
  }
}