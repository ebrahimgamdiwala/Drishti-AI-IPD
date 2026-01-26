/// Drishti App - Emergency Contacts Screen
///
/// Manage emergency contacts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/repositories/user_repository.dart';
import '../../widgets/inputs/custom_text_field.dart';
import '../../widgets/buttons/gradient_button.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final UserRepository _repository = UserRepository();
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    final user = context.read<AuthProvider>().user;
    if (user != null && user.emergencyContacts.isNotEmpty) {
      setState(() {
        _contacts = user.emergencyContacts.map((contact) {
          return {
            'name': contact.name ?? '',
            'email': contact.email ?? '',
            'phone': contact.phone ?? '',
            'relationship': contact.relationship ?? '',
          };
        }).toList();
      });
    }
  }

  Future<void> _saveContacts() async {
    setState(() => _isLoading = true);

    try {
      final updatedUser = await _repository.updateEmergencyContacts(_contacts);
      if (mounted) {
        context.read<AuthProvider>().updateUser(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency contacts updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update contacts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) => _ContactDialog(
        onSave: (contact) {
          setState(() {
            _contacts.add(contact);
          });
        },
      ),
    );
  }

  void _editContact(int index) {
    showDialog(
      context: context,
      builder: (context) => _ContactDialog(
        contact: _contacts[index],
        onSave: (contact) {
          setState(() {
            _contacts[index] = contact;
          });
        },
      ),
    );
  }

  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addContact),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _contacts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        return _buildContactCard(
                          _contacts[index],
                          index,
                          isDark,
                        );
                      },
                    ),
            ),
            if (_contacts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: GradientButton(
                  text: 'Save Changes',
                  isLoading: _isLoading,
                  onPressed: _saveContacts,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    Map<String, dynamic> contact,
    int index,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  contact['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editContact(index),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 20,
                  color: AppColors.error,
                ),
                onPressed: () => _deleteContact(index),
              ),
            ],
          ),
          if (contact['relationship'] != null &&
              contact['relationship'].isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              contact['relationship'],
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 14,
              ),
            ),
          ],
          if (contact['phone'] != null && contact['phone'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(contact['phone']),
              ],
            ),
          ],
          if (contact['email'] != null && contact['email'].isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email, size: 16, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(contact['email']),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 100 * index),
      duration: 300.ms,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emergency_outlined,
            size: 80,
            color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No emergency contacts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts who can be reached in case of emergency',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContactDialog extends StatefulWidget {
  final Map<String, dynamic>? contact;
  final Function(Map<String, dynamic>) onSave;

  const _ContactDialog({this.contact, required this.onSave});

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _relationshipController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.contact?['name'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.contact?['phone'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.contact?['email'] ?? '',
    );
    _relationshipController = TextEditingController(
      text: widget.contact?['relationship'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'relationship': _relationshipController.text.trim(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Name',
                hint: 'Enter name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _relationshipController,
                label: 'Relationship',
                hint: 'e.g., Spouse, Parent, Friend',
                prefixIcon: Icons.family_restroom,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone',
                hint: 'Enter phone number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
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
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
