import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';

class ManagerContactsScreen extends StatefulWidget {
  const ManagerContactsScreen({super.key});

  @override
  State<ManagerContactsScreen> createState() => _ManagerContactsScreenState();
}

class _ManagerContactsScreenState extends State<ManagerContactsScreen> {
  final DatabaseService _dbService = DatabaseService();
  UserModel? _landlord;

  @override
  void initState() {
    super.initState();
    _loadLandlord();
  }

  Future<void> _loadLandlord() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.assignedLandlordId != null) {
      final landlord = await _dbService.getUser(user!.assignedLandlordId!);
      if (mounted) {
        setState(() {
          _landlord = landlord;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Landlord Contact
          Text(
            'Landlord',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (_landlord != null)
            _buildContactCard(
              name: _landlord!.fullName,
              role: 'Property Owner',
              phone: _landlord!.phone,
              email: _landlord!.email,
              imageUrl: _landlord!.profileImageUrl,
              color: Theme.of(context).primaryColor,
            )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          const SizedBox(height: 24),

          // Tenants
          Text(
            'Tenants',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (user.assignedPropertyId != null)
            StreamBuilder<List<UserModel>>(
              stream: _dbService.getTenantsByProperty(user.assignedPropertyId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tenants = snapshot.data ?? [];

                if (tenants.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No tenants yet',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tenants.length,
                  itemBuilder: (context, index) {
                    final tenant = tenants[index];
                    return _buildContactCard(
                      name: tenant.fullName,
                      role: 'Tenant',
                      phone: tenant.phone,
                      email: tenant.email,
                      imageUrl: tenant.profileImageUrl,
                      color: Colors.blue.shade700,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required String name,
    required String role,
    required String phone,
    required String email,
    String? imageUrl,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.2),
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? Text(
                      name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.phone, color: Colors.green.shade700),
                  onPressed: () {
                    // TODO: Implement phone call
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling $phone...')),
                    );
                  },
                  tooltip: 'Call',
                ),
                IconButton(
                  icon: Icon(Icons.email, color: Colors.blue.shade700),
                  onPressed: () {
                    // TODO: Implement email
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Emailing $email...')),
                    );
                  },
                  tooltip: 'Email',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}