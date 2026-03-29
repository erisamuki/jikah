import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../models/property_model.dart';
import '../../models/unit_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  void _loadProperties() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      context.read<PropertyProvider>().loadPropertiesForLandlord(user.uid);
      context.read<PropertyProvider>().loadUnitsForLandlord(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        final properties = propertyProvider.properties;

        if (properties.isEmpty) {
          return EmptyState(
            icon: Icons.apartment,
            title: 'No Properties Yet',
            subtitle: 'Add your first property to get started',
            buttonText: 'Add Property',
            onButtonPressed: () => _showAddPropertyDialog(context),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async => _loadProperties(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                final units = propertyProvider.getUnitsForProperty(property.id);
                return _buildPropertyCard(property, units);
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddPropertyDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Property'),
          ),
        );
      },
    );
  }

  Widget _buildPropertyCard(PropertyModel property, List<UnitModel> units) {
    final occupiedCount = units.where((u) => u.status == UnitStatus.occupied).length;
    final vacantCount = units.where((u) => u.status == UnitStatus.vacant).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          child: Icon(
            _getPropertyIcon(property.type),
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          property.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(property.location),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge('${units.length} Units', Colors.blue),
                const SizedBox(width: 8),
                _buildBadge('$occupiedCount Occupied', Colors.green),
                const SizedBox(width: 8),
                _buildBadge('$vacantCount Vacant', Colors.orange),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditPropertyDialog(context, property);
            } else if (value == 'delete') {
              _showDeletePropertyDialog(context, property);
            } else if (value == 'add_unit') {
              _showAddUnitDialog(context, property);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'add_unit', child: Text('Add Unit')),
            const PopupMenuItem(value: 'edit', child: Text('Edit Property')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        children: [
          if (units.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.door_front_door, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No units added yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showAddUnitDialog(context, property),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Unit'),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getUnitStatusColor(unit.status).withValues(alpha: 0.2),
                    child: Icon(
                      Icons.door_front_door,
                      color: _getUnitStatusColor(unit.status),
                    ),
                  ),
                  title: Text('Unit ${unit.unitNumber}'),
                  subtitle: Text(unit.formattedRent),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          unit.statusDisplay,
                          style: TextStyle(
                            color: _getUnitStatusColor(unit.status),
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: _getUnitStatusColor(unit.status).withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditUnitDialog(context, unit);
                          } else if (value == 'delete') {
                            _showDeleteUnitDialog(context, unit);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit Unit')),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  IconData _getPropertyIcon(PropertyType type) {
    switch (type) {
      case PropertyType.hostel:
        return Icons.hotel;
      case PropertyType.rental:
        return Icons.home;
      case PropertyType.standaloneHouse:
        return Icons.house;
      case PropertyType.apartment:
        return Icons.apartment;
      case PropertyType.commercialBuilding:
        return Icons.business;
    }
  }

  Color _getUnitStatusColor(UnitStatus status) {
    switch (status) {
      case UnitStatus.occupied:
        return Colors.green;
      case UnitStatus.vacant:
        return Colors.orange;
      case UnitStatus.maintenance:
        return Colors.red;
    }
  }

  // ============ DIALOGS ============

  void _showAddPropertyDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final addressController = TextEditingController();
    final descriptionController = TextEditingController();
    PropertyType selectedType = PropertyType.rental;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Property'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nameController,
                    label: 'Property Name',
                    hint: 'e.g., Sunrise Apartments',
                    prefixIcon: Icons.apartment,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PropertyType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Property Type',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: PropertyType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getPropertyTypeName(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedType = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: locationController,
                    label: 'Location',
                    hint: 'e.g., Kampala, Ntinda',
                    prefixIcon: Icons.location_on,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: addressController,
                    label: 'Address (Optional)',
                    hint: 'Full address',
                    prefixIcon: Icons.pin_drop,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: descriptionController,
                    label: 'Description (Optional)',
                    hint: 'Brief description',
                    prefixIcon: Icons.description,
                    maxLines: 3,
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
            Consumer<PropertyProvider>(
              builder: (context, provider, _) => CustomButton(
                text: 'Add Property',
                isLoading: provider.isLoading,
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final user = context.read<AuthProvider>().currentUser;
                    if (user == null) return;

                    final success = await provider.createProperty(
                      landlordId: user.uid,
                      name: nameController.text.trim(),
                      location: locationController.text.trim(),
                      type: selectedType,
                      address: addressController.text.trim().isEmpty
                          ? null
                          : addressController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );

                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Property added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPropertyDialog(BuildContext context, PropertyModel property) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: property.name);
    final locationController = TextEditingController(text: property.location);
    final addressController = TextEditingController(text: property.address ?? '');
    final descriptionController = TextEditingController(text: property.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Property'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Property Name',
                  prefixIcon: Icons.apartment,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: locationController,
                  label: 'Location',
                  prefixIcon: Icons.location_on,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: addressController,
                  label: 'Address (Optional)',
                  prefixIcon: Icons.pin_drop,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: descriptionController,
                  label: 'Description (Optional)',
                  prefixIcon: Icons.description,
                  maxLines: 3,
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
          Consumer<PropertyProvider>(
            builder: (context, provider, _) => CustomButton(
              text: 'Save Changes',
              isLoading: provider.isLoading,
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await provider.updateProperty(property.id, {
                    'name': nameController.text.trim(),
                    'location': locationController.text.trim(),
                    'address': addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                    'description': descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  });

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Property updated!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeletePropertyDialog(BuildContext context, PropertyModel property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text(
          'Are you sure you want to delete "${property.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<PropertyProvider>(
            builder: (context, provider, _) => TextButton(
              onPressed: () async {
                final success = await provider.deleteProperty(property.id);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Property deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUnitDialog(BuildContext context, PropertyModel property) {
    final formKey = GlobalKey<FormState>();
    final unitNumberController = TextEditingController();
    final rentController = TextEditingController();
    final descriptionController = TextEditingController();
    int paymentDueDay = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Unit to ${property.name}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: unitNumberController,
                    label: 'Unit Number',
                    hint: 'e.g., A1, 101, Ground Floor',
                    prefixIcon: Icons.door_front_door,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: rentController,
                    label: 'Rent Amount (UGX)',
                    hint: 'e.g., 500000',
                    prefixIcon: Icons.money,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(v!) == null) return 'Invalid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: paymentDueDay,
                    decoration: const InputDecoration(
                      labelText: 'Payment Due Day',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: List.generate(28, (i) => i + 1).map((day) {
                      return DropdownMenuItem(
                        value: day,
                        child: Text('Day $day of each month'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => paymentDueDay = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: descriptionController,
                    label: 'Description (Optional)',
                    hint: 'e.g., 2 bedroom, self-contained',
                    prefixIcon: Icons.description,
                    maxLines: 2,
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
            Consumer<PropertyProvider>(
              builder: (context, provider, _) => CustomButton(
                text: 'Add Unit',
                isLoading: provider.isLoading,
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final user = context.read<AuthProvider>().currentUser;
                    if (user == null) return;

                    final success = await provider.createUnit(
                      propertyId: property.id,
                      landlordId: user.uid,
                      unitNumber: unitNumberController.text.trim(),
                      rentAmount: double.parse(rentController.text.trim()),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      paymentDueDay: paymentDueDay,
                    );

                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unit added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUnitDialog(BuildContext context, UnitModel unit) {
    final formKey = GlobalKey<FormState>();
    final unitNumberController = TextEditingController(text: unit.unitNumber);
    final rentController = TextEditingController(text: unit.rentAmount.toStringAsFixed(0));
    final descriptionController = TextEditingController(text: unit.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Unit'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: unitNumberController,
                  label: 'Unit Number',
                  prefixIcon: Icons.door_front_door,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: rentController,
                  label: 'Rent Amount (UGX)',
                  prefixIcon: Icons.money,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(v!) == null) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: descriptionController,
                  label: 'Description (Optional)',
                  prefixIcon: Icons.description,
                  maxLines: 2,
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
          Consumer<PropertyProvider>(
            builder: (context, provider, _) => CustomButton(
              text: 'Save Changes',
              isLoading: provider.isLoading,
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await provider.updateUnit(unit.id, {
                    'unitNumber': unitNumberController.text.trim(),
                    'rentAmount': double.parse(rentController.text.trim()),
                    'description': descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  });

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unit updated!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteUnitDialog(BuildContext context, UnitModel unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text(
          'Are you sure you want to delete Unit ${unit.unitNumber}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<PropertyProvider>(
            builder: (context, provider, _) => TextButton(
              onPressed: () async {
                final success = await provider.deleteUnit(unit.id, unit.propertyId);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unit deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  String _getPropertyTypeName(PropertyType type) {
    switch (type) {
      case PropertyType.hostel:
        return 'Hostel';
      case PropertyType.rental:
        return 'Rental';
      case PropertyType.standaloneHouse:
        return 'Standalone House';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.commercialBuilding:
        return 'Commercial Building';
    }
  }
}