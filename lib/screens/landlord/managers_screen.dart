import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ManagersScreen extends StatefulWidget {
  const ManagersScreen({super.key});

  @override
  State<ManagersScreen> createState() => _ManagersScreenState();
}

class _ManagersScreenState extends State<ManagersScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<List<UserModel>>(
      stream: _dbService.getManagersByLandlord(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final managers = snapshot.data ?? [];

        if (managers.isEmpty) {
          return EmptyState(
            icon: Icons.manage_accounts,
            title: 'No Managers Yet',
            subtitle: 'Add managers to help manage your properties',
            buttonText: 'Add Manager',
            onButtonPressed: () => _showAddManagerDialog(context),
          );
        }

        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: managers.length,
            itemBuilder: (context, index) {
              final manager = managers[index];
              return _buildManagerCard(manager);
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddManagerDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Manager'),
          ),
        );
      },
    );
  }

  Widget _buildManagerCard(UserModel manager) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.2),
          backgroundImage: manager.profileImageUrl != null
              ? NetworkImage(manager.profileImageUrl!)
              : null,
          child: manager.profileImageUrl == null
              ? Text(
                  manager.fullName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          manager.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(manager.phone),
            Text(
              manager.email,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              _showManagerDetailsDialog(context, manager);
            } else if (value == 'contact') {
              _showContactDialog(context, manager);
            } else if (value == 'remove') {
              _showRemoveManagerDialog(context, manager);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'contact', child: Text('Contact')),
            const PopupMenuItem(
              value: 'remove',
              child: Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showAddManagerDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final locationController = TextEditingController();
    
    String? selectedPropertyId;

    final propertyProvider = context.read<PropertyProvider>();
    final properties = propertyProvider.properties;

    if (properties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a property first before adding a manager'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Manager'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nameController,
                    label: 'Full Name',
                    prefixIcon: Icons.person,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: emailController,
                    label: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (!v!.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: phoneController,
                    label: 'Phone Number',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: passwordController,
                    label: 'Temporary Password',
                    prefixIcon: Icons.lock,
                    hint: 'Manager will use this to login',
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (v!.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: locationController,
                    label: 'Location',
                    prefixIcon: Icons.location_on,
                    hint: 'e.g., Kampala, Ntinda',
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPropertyId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to Property',
                      prefixIcon: Icon(Icons.apartment),
                    ),
                    items: properties.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedPropertyId = value);
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: 'Add Manager',
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final user = context.read<AuthProvider>().currentUser;
                  if (user == null) return;

                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  final authService = AuthService();
                  final result = await authService.createManager(
                    fullName: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    password: passwordController.text,
                    landlordId: user.uid,
                    propertyId: selectedPropertyId!,
                    location: locationController.text.trim(),
                  );

                  // Re-login the landlord since creating a user signs them out
                  if (result['success']) {
                    await context.read<AuthProvider>().initialize();
                  }

                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    Navigator.pop(context); // Close dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['success']
                              ? 'Manager added successfully!'
                              : result['message'] ?? 'Failed to add manager',
                        ),
                        backgroundColor:
                            result['success'] ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showManagerDetailsDialog(BuildContext context, UserModel manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(manager.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', manager.email),
              _buildDetailRow('Phone', manager.phone),
              _buildDetailRow('Role', 'Property Manager'),
              _buildDetailRow(
                'Joined',
                '${manager.createdAt.day}/${manager.createdAt.month}/${manager.createdAt.year}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context, UserModel manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${manager.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(manager.phone),
              subtitle: const Text('Tap to call'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(manager.email),
              subtitle: const Text('Tap to email'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRemoveManagerDialog(BuildContext context, UserModel manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Manager'),
        content: Text(
          'Are you sure you want to remove ${manager.fullName}? They will no longer have access to the system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await _dbService.deactivateUser(manager.uid);

              // Remove manager from property
              if (manager.assignedPropertyId != null) {
                await _dbService.updateProperty(manager.assignedPropertyId!, {
                  'managerId': null,
                });
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Manager removed successfully'
                          : 'Failed to remove manager',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}