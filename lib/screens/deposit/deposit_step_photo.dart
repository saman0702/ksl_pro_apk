import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

class DepositStepPhoto extends StatefulWidget {
  const DepositStepPhoto({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final ExpeditionDraft draft;
  final VoidCallback onChanged;

  @override
  State<DepositStepPhoto> createState() => _DepositStepPhotoState();
}

class _DepositStepPhotoState extends State<DepositStepPhoto> {
  final _picker = ImagePicker();
  bool _loading = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _ensurePermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted;
    }

    var status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;

    // Android ≤ 12
    status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _pick(ImageSource source) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final granted = await _ensurePermission(source);
      if (!granted) {
        _snack(
          source == ImageSource.camera
              ? 'Autorisez l\'accès à la caméra pour prendre une photo.'
              : 'Autorisez l\'accès à la galerie pour choisir une photo.',
        );
        return;
      }

      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 65,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      widget.draft.photoPath = file.path;
      widget.draft.photoBase64 = base64Encode(bytes);
      widget.onChanged();
    } on PlatformException catch (e) {
      _snack(
        e.code == 'channel-error'
            ? 'Photo indisponible — fermez puis relancez l\'application (rebuild complet après installation).'
            : 'Impossible d\'accéder à ${source == ImageSource.camera ? 'la caméra' : 'la galerie'}.',
      );
    } catch (e) {
      _snack('Impossible d\'ajouter la photo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clear() {
    widget.draft.photoPath = null;
    widget.draft.photoBase64 = null;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final path = widget.draft.photoPath;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Photo du colis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ext.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Optionnel — ajoutez une photo pour faciliter l\'identification du colis.',
          style: TextStyle(color: ext.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: KatianColors.red))
        else if (path != null && File(path).existsSync())
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(path),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Supprimer la photo'),
              ),
            ],
          )
        else
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ext.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ext.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera_outlined, size: 48, color: ext.textSecondary),
                const SizedBox(height: 8),
                Text('Aucune photo', style: TextStyle(color: ext.textSecondary)),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Caméra'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galerie'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
