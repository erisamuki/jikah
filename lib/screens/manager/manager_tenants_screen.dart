import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/unit_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ManagerTenantsScreen extends StatefulWidget {
  const ManagerTenantsScreen({super.key});

  @override
  State<ManagerTenantsScreen> createState() => _ManagerTenantsScreenState();
}

class _ManagerTenantsScreenState extends State<ManagerTenantsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<UnitModel> _vacantUnits = [];

  @override
  void initState() {
    super.initState();
    _loadVacantUnits();
  }

  Future<void> _loadVacantUnits() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.assignedPropertyId != null) {
      _dbService.getUnitsByProperty(user!.assignedPropertyId!).listen((units) {
        if (mounted) {
          setState(() {
            _vacantUnits = units.where((u) => u.status == UnitStatus.vacant).toList();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null || user.assignedPropertyId == null) {
      return const Center(child: Text('No property assigned'));
    }

    return StreamBuilder<List<UserModel>>(
      stream: _dbService.getTenantsByProperty(user.assignedPropertyId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tenants = snapshot.data ?? [];

        if (tenants.isEmpty) {
          return EmptyState(
            icon: Icons.people,
            title: 'No Tenants Yet',
            subtitle: 'Add tenants to this property',
            buttonText: 'Add Tenant',
            onButtonPressed: _vacantUnits.isNotEmpty
                ? () => _showAddTenantDialog(context, user)
                : null,
          );
        }

        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              return _buildTenantCard(tenant);
            },
          ),
          floatingActionButton: _vacantUnits.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddTenantDialog(context, user),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Tenant'),
                  backgroundColor: Colors.blue.shade700,
                )
              : null,
        );
      },
    );
  }

  Widget _buildTenantCard(UserModel tenant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.2),
          backgroundImage: tenant.profileImageUrl != null
              ? NetworkImage(tenant.profileImageUrl!)
              : null,
          child: tenant.profileImageUrl == null
              ? Text(
                  tenant.fullName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          tenant.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tenant.phone),
            Text(
              tenant.email,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              _showTenantDetailsDialog(context, tenant);
            } else if (value == 'contact') {
              _showContactDialog(context, tenant);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'contact', child: Text('Contact')),
            // Note: Managers cannot remove tenants - only landlords can
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showAddTenantDialog(BuildContext context, UserModel manager) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final ninController = TextEditingController();
  final nextOfKinController = TextEditingController();
  final nextOfKinContactController = TextEditingController();

  String? selectedUnitId;
  bool isLoading = false;

  if (_vacantUnits.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No vacant units available'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Add Tenant'),
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
                  hint: 'Tenant will use this to login',
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (v!.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedUnitId,
                  decoration: const InputDecoration(
                    labelText: 'Select Unit',
                    prefixIcon: Icon(Icons.door_front_door),
                  ),
                  items: _vacantUnits.map((u) {
                    return DropdownMenuItem(
                      value: u.id,
                      child: Text('Unit ${u.unitNumber} - ${u.formattedRent}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedUnitId = value);
                  },
                  validator: (v) => v == null ? 'Select a unit' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: ninController,
                  label: 'NIN / Passport',
                  prefixIcon: Icons.badge,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: nextOfKinController,
                  label: 'Next of Kin',
                  prefixIcon: Icons.family_restroom,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: nextOfKinContactController,
                  label: 'Next of Kin Contact',
                  prefixIcon: Icons.phone_callback,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
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
            onPressed: isLoading
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;

                    setState(() => isLoading = true);

                    final authService = AuthService();
                    final result = await authService.createTenant(
                      fullName: nameController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                      password: passwordController.text,
                      landlordId: manager.assignedLandlordId!,
                      propertyId: manager.assignedPropertyId!,
                      unitId: selectedUnitId!,
                      ninOrPassport: ninController.text.trim(),
                      nextOfKin: nextOfKinController.text.trim(),
                      nextOfKinContact: nextOfKinContactController.text.trim(),
                    );

                    setState(() => isLoading = false);

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['success']
                                ? 'Tenant added successfully!'
                                : result['message'] ?? 'Failed to add tenant',
                          ),
                          backgroundColor:
                              result['success'] ? Colors.green : Colors.red,
                        ),
                      );

                      if (result['success']) {
                        _loadVacantUnits();
                      }
                    }
                  },
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Add Tenant'),
          ),
        ],
      ),
    ),
  );
}

  void _showTenantDetailsDialog(BuildContext context, UserModel tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tenant.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', tenant.email),
              _buildDetailRow('Phone', tenant.phone),
              if (tenant.ninOrPassport != null)
                _buildDetailRow('NIN/Passport', tenant.ninOrPassport!),
              if (tenant.nextOfKin != null)
                _buildDetailRow('Next of Kin', tenant.nextOfKin!),
              if (tenant.nextOfKinContact != null)
                _buildDetailRow('Next of Kin Contact', tenant.nextOfKinContact!),
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
            width: 120,
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

  void _showContactDialog(BuildContext context, UserModel tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${tenant.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(tenant.phone),
              subtitle: const Text('Tap to call'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement phone call
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(tenant.email),
              subtitle: const Text('Tap to email'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement email
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
}