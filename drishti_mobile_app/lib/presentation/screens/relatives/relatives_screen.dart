/// Drishti App - Relatives Screen
///
/// Known persons list with CRUD operations.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/models/relative_model.dart';
import '../../../data/repositories/relatives_repository.dart';
import '../../../data/services/voice_service.dart';
import '../../widgets/cards/person_card.dart';
import '../../widgets/inputs/custom_text_field.dart';
import '../../widgets/buttons/gradient_button.dart';

class RelativesScreen extends StatefulWidget {
  const RelativesScreen({super.key});

  @override
  State<RelativesScreen> createState() => _RelativesScreenState();
}

class _RelativesScreenState extends State<RelativesScreen> {
  final RelativesRepository _repository = RelativesRepository();
  final VoiceService _voiceService = VoiceService();

  List<RelativeModel> _relatives = [];
  bool _isLoading = true;
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _loadRelatives();
  }

  Future<void> _loadRelatives() async {
    setState(() => _isLoading = true);

    try {
      _relatives = await _repository.getRelatives();
      _sortRelatives(_sortBy);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load relatives: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addRelative() async {
    final result = await showModalBottomSheet<RelativeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddRelativeSheet(),
    );

    if (result != null) {
      _loadRelatives(); // Reload to get updated list
      _voiceService.speak('${result.name} added successfully.');
    }
  }

  Future<void> _editRelative(RelativeModel relative) async {
    final result = await showModalBottomSheet<RelativeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddRelativeSheet(relative: relative),
    );

    if (result != null) {
      _loadRelatives();
    }
  }

  Future<void> _deleteRelative(RelativeModel relative) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Relative'),
        content: Text('Are you sure you want to delete ${relative.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteRelative(relative.id);
        setState(() {
          _relatives.removeWhere((r) => r.id == relative.id);
        });
        _voiceService.speak('${relative.name} deleted.');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete relative: $e')),
          );
        }
      }
    }
  }

  void _sortRelatives(String by) {
    setState(() {
      _sortBy = by;
      switch (by) {
        case 'name':
          _relatives.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'recent':
          _relatives.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          break;
        case 'relationship':
          _relatives.sort((a, b) => a.relationship.compareTo(b.relationship));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.relatives,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                    tooltip: 'Search',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Filter',
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),

            // Sort options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Sort By',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 12),
                  _SortChip(
                    label: 'A→Z',
                    isSelected: _sortBy == 'name',
                    onTap: () => _sortRelatives('name'),
                  ),
                  _SortChip(
                    label: 'Recent',
                    isSelected: _sortBy == 'recent',
                    onTap: () => _sortRelatives('recent'),
                  ),
                  _SortChip(
                    label: 'Relation',
                    isSelected: _sortBy == 'relationship',
                    onTap: () => _sortRelatives('relationship'),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _relatives.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _relatives.length,
                      itemBuilder: (context, index) {
                        final relative = _relatives[index];
                        return PersonCard(
                              relative: relative,
                              onTap: () => _editRelative(relative),
                              onEdit: () => _editRelative(relative),
                              onDelete: () => _deleteRelative(relative),
                            )
                            .animate()
                            .fadeIn(
                              delay: Duration(
                                milliseconds: 200 + (index * 100),
                              ),
                              duration: 300.ms,
                            )
                            .slideX(begin: 0.1, end: 0);
                      },
                    ),
            ),
          ],
        );
          },
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
                onPressed: _addRelative,
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.addRelative),
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              )
              .animate()
              .fadeIn(delay: 500.ms, duration: 300.ms)
              .slideY(begin: 0.5, end: 0),
    );
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
            'No relatives added yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first relative',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

// Add Relative Bottom Sheet
class AddRelativeSheet extends StatefulWidget {
  final RelativeModel? relative;

  const AddRelativeSheet({super.key, this.relative});

  @override
  State<AddRelativeSheet> createState() => _AddRelativeSheetState();
}

class _AddRelativeSheetState extends State<AddRelativeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _notesController = TextEditingController();
  final RelativesRepository _repository = RelativesRepository();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _localImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.relative != null) {
      _nameController.text = widget.relative!.name;
      _relationshipController.text = widget.relative!.relationship;
      _notesController.text = widget.relative!.notes ?? '';
      if (widget.relative!.images.isNotEmpty) {
        // For network images, we just show them. Local path might not be valid for network images.
        // We rely on PersonCard's logic or just show the network image if no local file.
        // But here we need to show the current image.
        // We can use the URL from relative.images.first.path
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      RelativeModel? result;

      if (widget.relative == null) {
        // Add new relative
        if (_selectedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an image')),
          );
          setState(() => _isLoading = false);
          return;
        }

        result = await _repository.addRelative(
          name: _nameController.text.trim(),
          relationship: _relationshipController.text.trim(),
          image: _selectedImage!,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      } else {
        // Update existing relative
        final updatedRelative = widget.relative!.copyWith(
          name: _nameController.text.trim(),
          relationship: _relationshipController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        result = await _repository.updateRelative(updatedRelative);

        // If image changed, upload it
        if (_selectedImage != null) {
          result = await _repository.addPhoto(result.id, _selectedImage!);
        }
      }

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.relative != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? AppStrings.editRelative : AppStrings.addRelative,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Photo picker
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Take Photo'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImage();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Choose from Gallery'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickFromGallery();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.lightInputFill,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryBlue.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: _selectedImage != null
                              ? Image.file(_selectedImage!, fit: BoxFit.cover)
                              : (widget.relative?.images.isNotEmpty ?? false)
                              ? Image.network(
                                  widget.relative!.images.first.path.startsWith(
                                        'http',
                                      )
                                      ? widget.relative!.images.first.path
                                      : '${ApiEndpoints.baseUrl}${widget.relative!.images.first.path}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.primaryBlue,
                                  ),
                                )
                              : _localImagePath != null
                              ? Image.file(
                                  File(_localImagePath!),
                                  fit: BoxFit.cover,
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: AppColors.primaryBlue,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

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
                      label: AppStrings.relationship,
                      hint: 'e.g., Mother, Father, Friend',
                      prefixIcon: Icons.family_restroom,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter relationship';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _notesController,
                      label: AppStrings.notes,
                      hint: 'Optional notes...',
                      prefixIcon: Icons.notes,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    GradientButton(
                      text: isEditing ? 'Save Changes' : 'Add Relative',
                      isLoading: _isLoading,
                      onPressed: _save,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
