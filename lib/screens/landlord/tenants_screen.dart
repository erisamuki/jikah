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

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    // Make sure properties/units are loaded as soon as this screen mounts,
    // so the Add Tenant dropdowns have data the moment they're opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      final propertyProvider = context.read<PropertyProvider>();
      if (user != null) {
        if (propertyProvider.properties.isEmpty) {
          propertyProvider.loadPropertiesForLandlord(user.uid);
        }
        if (propertyProvider.units.isEmpty) {
          propertyProvider.loadUnitsForLandlord(user.uid);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<List<UserModel>>(
      stream: _dbService.getTenantsByLandlord(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tenants = snapshot.data ?? [];

        if (tenants.isEmpty) {
          return EmptyState(
            icon: Icons.people,
            title: 'No Tenants Yet',
            subtitle: 'Add tenants to your properties',
            buttonText: 'Add Tenant',
            onButtonPressed: () => _showAddTenantDialog(context),
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddTenantDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Tenant'),
          ),
        );
      },
    );
  }

  Widget _buildTenantCard(UserModel tenant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          backgroundImage: tenant.profileImageUrl != null
              ? NetworkImage(tenant.profileImageUrl!)
              : null,
          child: tenant.profileImageUrl == null
              ? Text(
                  tenant.fullName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(tenant.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tenant.phone),
            Text(tenant.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              _showTenantDetailsDialog(context, tenant);
            } else if (value == 'contact') {
              _showContactDialog(context, tenant);
            } else if (value == 'remove') {
              _showRemoveTenantDialog(context, tenant);
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

  void _showAddTenantDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final ninController = TextEditingController();
    final nextOfKinController = TextEditingController();
    final nextOfKinContactController = TextEditingController();

    String? selectedPropertyId;
    String? selectedUnitId;
    List<UnitModel> availableUnits = [];
    final scrollController = ScrollController();

    final user = context.read<AuthProvider>().currentUser;

    // Kick off a load in case the provider is still empty (e.g. dialog
    // opened before initState's postFrameCallback finished, or on a
    // fresh hot-reload).
    if (user != null) {
      final propertyProvider = context.read<PropertyProvider>();
      if (propertyProvider.properties.isEmpty) {
        propertyProvider.loadPropertiesForLandlord(user.uid);
      }
      if (propertyProvider.units.isEmpty) {
        propertyProvider.loadUnitsForLandlord(user.uid);
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          // Watching here (via Consumer below) makes the dialog rebuild
          // itself the instant properties/units arrive, instead of being

          // frozen with whatever was in the provider the moment the
          // dialog first opened.
          return Consumer<PropertyProvider>(
            builder: (context, propertyProvider, _) {
              final properties = propertyProvider.properties;

              // Keep availableUnits in sync with the provider's live data
              // for the currently selected property.
              if (selectedPropertyId != null) {
                availableUnits = propertyProvider.units
                    .where(
                      (u) => u.propertyId == selectedPropertyId && u.status == UnitStatus.vacant,
                    )
                    .toList();
              }

              final screenSize = MediaQuery.of(dialogContext).size;

              return AlertDialog(
                title: const Text('Add Tenant'),
                content: SizedBox(
                  width: double.maxFinite,
                  // Cap the dialog's height so it can never grow past the
                  // window/screen. Without this, AlertDialog just expands
                  // to fit its content and the inner SingleChildScrollView
                  // never has anything to scroll, because nothing is
                  // actually overflowing *inside* it.
                  height: screenSize.height * 0.7,
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: scrollController,
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
                              initialValue: selectedPropertyId,
                              decoration: InputDecoration(
                                labelText: 'Select Property',
                                prefixIcon: const Icon(Icons.apartment),
                                hintText: properties.isEmpty
                                    ? 'No properties yet — add one first'
                                    : null,
                              ),
                              items: properties
                                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                                  .toList(),
                              onChanged: properties.isEmpty
                                  ? null
                                  : (value) {
                                      setState(() {
                                        selectedPropertyId = value;
                                        selectedUnitId = null;
                                        availableUnits = propertyProvider.units
                                            .where(
                                              (u) =>
                                                  u.propertyId == value &&
                                                  u.status == UnitStatus.vacant,
                                            )
                                            .toList();
                                      });
                                    },
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: selectedUnitId,
                              decoration: InputDecoration(
                                labelText: 'Select Unit',
                                prefixIcon: const Icon(Icons.door_front_door),
                                hintText: selectedPropertyId == null
                                    ? 'Select a property first'
                                    : (availableUnits.isEmpty
                                          ? 'No vacant units for this property'
                                          : null),
                              ),
                              items: availableUnits
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u.id,
                                      child: Text('Unit ${u.unitNumber} - ${u.formattedRent}'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: availableUnits.isEmpty
                                  ? null
                                  : (value) {
                                      setState(() => selectedUnitId = value);
                                    },
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: ninController,
                              label: 'NIN / Passport (Optional)',
                              prefixIcon: Icons.badge,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: nextOfKinController,
                              label: 'Next of Kin (Optional)',
                              prefixIcon: Icons.family_restroom,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: nextOfKinContactController,
                              label: 'Next of Kin Contact (Optional)',
                              prefixIcon: Icons.phone_callback,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  CustomButton(
                    text: 'Add Tenant',
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final currentUser = context.read<AuthProvider>().currentUser;
                        if (currentUser == null) return;

                        // Show loading
                        showDialog(
                          context: dialogContext,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        final authService = AuthService();
                        final result = await authService.createTenant(
                          fullName: nameController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                          password: passwordController.text,
                          landlordId: currentUser.uid,
                          propertyId: selectedPropertyId!,
                          unitId: selectedUnitId!,
                          ninOrPassport: ninController.text.trim().isEmpty
                              ? null
                              : ninController.text.trim(),
                          nextOfKin: nextOfKinController.text.trim().isEmpty
                              ? null
                              : nextOfKinController.text.trim(),
                          nextOfKinContact: nextOfKinContactController.text.trim().isEmpty
                              ? null
                              : nextOfKinContactController.text.trim(),
                        );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext); // Close loading
                          Navigator.pop(dialogContext); // Close dialog

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['success']
                                    ? 'Tenant added successfully!'
                                    : result['message'] ?? 'Failed to add tenant',
                              ),
                              backgroundColor: result['success'] ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    ).then((_) {
      // Dialog closed (Cancel, successful add, or dismissed) — clean up
      // the ScrollController so it doesn't leak.
      scrollController.dispose();
    });
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
              if (tenant.nextOfKin != null) _buildDetailRow('Next of Kin', tenant.nextOfKin!),
              if (tenant.nextOfKinContact != null)
                _buildDetailRow('Next of Kin Contact', tenant.nextOfKinContact!),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
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
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
                // TODO: Implement phone call
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(tenant.email),
              subtitle: const Text('Tap to email'),
              onTap: () {
                // TODO: Implement email
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showRemoveTenantDialog(BuildContext context, UserModel tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Tenant'),
        content: Text(
          'Are you sure you want to remove ${tenant.fullName}? They will no longer have access to the system.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await _dbService.deactivateUser(tenant.uid);

              // Also remove tenant from unit
              if (tenant.assignedUnitId != null && tenant.assignedPropertyId != null) {
                await _dbService.removeTenantFromUnit(
                  tenant.assignedUnitId!,
                  tenant.assignedPropertyId!,
                );
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Tenant removed successfully' : 'Failed to remove tenant',
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
