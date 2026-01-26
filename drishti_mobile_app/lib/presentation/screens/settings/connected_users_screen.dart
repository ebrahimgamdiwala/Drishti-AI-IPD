/// Drishti App - Connected Users Screen
///
/// Display and manage connected users.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/user_repository.dart';

class ConnectedUsersScreen extends StatefulWidget {
  const ConnectedUsersScreen({super.key});

  @override
  State<ConnectedUsersScreen> createState() => _ConnectedUsersScreenState();
}

class _ConnectedUsersScreenState extends State<ConnectedUsersScreen> {
  final UserRepository _repository = UserRepository();
  List<dynamic> _connectedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnectedUsers();
  }

  Future<void> _loadConnectedUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await _repository.getConnectedUsers();
      setState(() {
        _connectedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load connected users: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Connected Users'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _connectedUsers.isEmpty
          ? _buildEmptyState()
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _connectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _connectedUsers[index];
                  return _buildUserCard(user, isDark, index);
                },
              ),
            ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isDark, int index) {
    return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Container(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryBlue,
                    size: 28,
                  ),
                ),
              ),
            ),
            title: Text(
              user['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email'] ?? ''),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user['role']?.toString().toUpperCase() ?? 'USER',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 * index),
          duration: 300.ms,
        )
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No connected users',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with family members or caregivers',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
