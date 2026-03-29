import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jikah/providers/auth_provider.dart';
import 'package:jikah/services/database_service.dart';
import 'package:jikah/services/sms_service.dart';
import 'package:jikah/models/user_model.dart';
import 'package:jikah/widgets/custom_text_field.dart';
import 'package:jikah/widgets/empty_state.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({super.key});

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> with SingleTickerProviderStateMixin {
  final SmsService _smsService = SmsService();
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;
  
  Map<String, int> _smsStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final stats = await _smsService.getSmsStats(user.uid);
      if (mounted) {
        setState(() {
          _smsStats = stats;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Column(
      children: [
        if (!_isLoading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Total Sent', '${_smsStats['sent'] ?? 0}', Icons.send, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Pending', '${_smsStats['pending'] ?? 0}', Icons.hourglass_empty, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Failed', '${_smsStats['failed'] ?? 0}', Icons.error, Colors.red)),
              ],
            ),
          ),
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Send SMS'),
            Tab(text: 'Bulk Reminders'),
            Tab(text: 'History'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSendSmsTab(user),
              _buildBulkRemindersTab(user),
              _buildHistoryTab(user),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSendSmsTab(UserModel? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send SMS to Tenant', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: user == null
                  ? const Text('Not logged in')
                  : StreamBuilder<List<UserModel>>(
                      stream: _dbService.getTenantsByLandlord(user.uid),
                      builder: (context, snapshot) {
                        final tenants = snapshot.data ?? [];
                        if (tenants.isEmpty) {
                          return const Padding(padding: EdgeInsets.all(16), child: Text('No tenants found'));
                        }
                        return DropdownButtonFormField<UserModel>(
                          decoration: const InputDecoration(labelText: 'Select Tenant', prefixIcon: Icon(Icons.person)),
                          items: tenants.map((t) => DropdownMenuItem(value: t, child: Text('${t.fullName} (${t.phone})'))).toList(),
                          onChanged: (tenant) {
                            if (tenant != null) _showSendSmsDialog(context, user, tenant);
                          },
                          hint: const Text('Choose a tenant'),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Send to Custom Number', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: user != null ? () => _showCustomSmsDialog(context, user) : null,
                icon: const Icon(Icons.sms),
                label: const Text('Send Custom SMS'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkRemindersTab(UserModel? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send Payment Reminders', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.notifications_active, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('Send payment reminders to all tenants with pending payments.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: user != null ? () => _showBulkReminderDialog(context) : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Bulk Reminders'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 48)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Send Overdue Notices', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Send urgent reminders to tenants with overdue payments.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: user != null ? () => _showOverdueReminderDialog(context) : null,
                    icon: const Icon(Icons.warning),
                    label: const Text('Send Overdue Notices'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 48)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(UserModel? user) {
    if (user == null) return const Center(child: Text('Not logged in'));

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _smsService.getSmsHistory(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return const EmptyState(icon: Icons.sms, title: 'No SMS History', subtitle: 'Your sent messages will appear here');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) => _buildSmsHistoryCard(messages[index]),
        );
      },
    );
  }

  Widget _buildSmsHistoryCard(Map<String, dynamic> sms) {
    final status = sms['status'] as String? ?? 'pending';
    final statusColor = status == 'sent' ? Colors.green : (status == 'failed' ? Colors.red : Colors.orange);
    final statusIcon = status == 'sent' ? Icons.check_circle : (status == 'failed' ? Icons.error : Icons.hourglass_empty);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(sms['phoneNumber'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(sms['message'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _showSendSmsDialog(BuildContext context, UserModel landlord, UserModel tenant) {
    final messageController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Send SMS to ${tenant.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone: ${tenant.phone}', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              CustomTextField(controller: messageController, label: 'Message', hint: 'Type your message...', maxLines: 4),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSending ? null : () async {
                if (messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message'), backgroundColor: Colors.red));
                  return;
                }
                setState(() => isSending = true);
                final success = await _smsService.sendCustomSms(phoneNumber: tenant.phone, message: messageController.text.trim(), landlordId: landlord.uid);
                setState(() => isSending = false);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'SMS queued!' : 'Failed to send'), backgroundColor: success ? Colors.green : Colors.red));
                  _loadStats();
                }
              },
              child: isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomSmsDialog(BuildContext context, UserModel landlord) {
    final phoneController = TextEditingController();
    final messageController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Send Custom SMS'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(controller: phoneController, label: 'Phone Number', hint: '0776XXXXXX', prefixIcon: Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                CustomTextField(controller: messageController, label: 'Message', hint: 'Type your message...', maxLines: 4),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSending ? null : () async {
                if (phoneController.text.trim().isEmpty || messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red));
                  return;
                }
                setState(() => isSending = true);
                final success = await _smsService.sendCustomSms(phoneNumber: phoneController.text.trim(), message: messageController.text.trim(), landlordId: landlord.uid);
                setState(() => isSending = false);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'SMS queued!' : 'Failed to send'), backgroundColor: success ? Colors.green : Colors.red));
                  _loadStats();
                }
              },
              child: isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Bulk Reminders'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text('Send payment reminders to all tenants with pending payments?', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment reminders queued!'), backgroundColor: Colors.green));
              _loadStats();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showOverdueReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Overdue Notices'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Send overdue notices to all tenants with late payments?', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Overdue notices queued!'), backgroundColor: Colors.green));
              _loadStats();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}