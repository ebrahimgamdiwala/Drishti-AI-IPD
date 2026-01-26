/// Drishti App - Favorites Screen
///
/// Display and manage favorite known persons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/repositories/user_repository.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final UserRepository _repository = UserRepository();
  List<dynamic> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      final favorites = await _repository.getFavorites();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load favorites: $e')));
      }
    }
  }

  Future<void> _removeFromFavorites(String personId, String name) async {
    try {
      await _repository.removeFromFavorites(personId);
      setState(() {
        _favorites.removeWhere((fav) => fav['id'] == personId);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name removed from favorites')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove from favorites: $e')),
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
        title: const Text('Favorites'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? _buildEmptyState()
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final favorite = _favorites[index];
                  return _buildFavoriteCard(favorite, isDark, index);
                },
              ),
            ),
    );
  }

  Widget _buildFavoriteCard(
    Map<String, dynamic> favorite,
    bool isDark,
    int index,
  ) {
    final images = favorite['images'] as List?;
    final hasImage = images != null && images.isNotEmpty;

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
                child: hasImage
                    ? Image.network(
                        images.first['path'].toString().startsWith('http')
                            ? images.first['path']
                            : '${ApiEndpoints.baseUrl}${images.first['path']}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, _) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            title: Text(
              favorite['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(favorite['relationship'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: AppColors.error),
              onPressed: () =>
                  _removeFromFavorites(favorite['id'], favorite['name'] ?? ''),
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

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryBlue.withValues(alpha: 0.1),
      child: const Icon(Icons.person, color: AppColors.primaryBlue, size: 28),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add relatives to favorites for quick access',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
