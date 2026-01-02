import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/app_user.dart';
import '../../services/profile_service.dart';

class EditProfileSheet extends StatefulWidget {
  final AppUser user;
  final ProfileService service;
  final bool focusAvatar;

  const EditProfileSheet({
    super.key,
    required this.user,
    required this.service,
    this.focusAvatar = false,
  });

  static Future<void> show(
    BuildContext context,
    AppUser user,
    ProfileService service, {
    bool focusAvatar = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditProfileSheet(
          user: user,
          service: service,
          focusAvatar: focusAvatar,
        ),
      ),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _uploadAvatarFile(File file) async {
    final url = await widget.service.uploadAvatar(widget.user.uid, file);
    await widget.service.updatePhotoUrl(widget.user.uid, url);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Avatar updated')));
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.service.updateDisplayName(widget.user.uid, name);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
      );
      if (picked == null) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      final file = File(picked.path);
      await _uploadAvatarFile(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to upload avatar')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _captureAndUploadAvatar() async {
    if (_saving) return;
    // Camera doesn't work on web browsers
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera is not supported on web. Please use "Pick a photo from your gallery" option instead.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    try {
      setState(() => _saving = true);
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 900,
      );
      if (picked == null) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      final file = File(picked.path);
      await _uploadAvatarFile(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to upload avatar')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.user.photoUrl != null
                  ? NetworkImage(widget.user.photoUrl!)
                  : null,
              child: widget.user.photoUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: const Text('Change profile photo'),
            subtitle: const Text('Pick a photo from your gallery'),
            trailing: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _saving ? null : _pickAndUploadAvatar,
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            subtitle: const Text('Use your camera for a new picture'),
            trailing: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _saving ? null : _captureAndUploadAvatar,
          ),
          const Divider(),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Display name'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveName(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveName,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
