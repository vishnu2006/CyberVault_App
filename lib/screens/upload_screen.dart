import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../helpers/auto_lock_helper.dart';
import '../widgets/encryption_success_animation.dart';
import '../models/document_access_log.dart';
import '../utils/document_tagger.dart';
import '../models/document_metadata.dart';
import '../services/documents_repository.dart';
import '../services/encryption_service.dart';

/// Upload flow: Encrypt (AES-256-GCM) → Base64 → Store in Firestore.
class UploadScreen extends StatefulWidget {
  static const routeName = '/upload';

  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  double _progress = 0;
  bool _uploading = false;
  String? _selectedFileName;

  List<DocumentAccessLog> get _logs =>
      DocumentsRepository.instance.accessLogs;

  void _showEncryptionAnimation(BuildContext ctx, String fileName) {
    setState(() => _uploading = false);
    final nav = Navigator.of(ctx);
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => EncryptionSuccessAnimation(
        fileName: fileName,
        onComplete: () {
          nav.pop();
          nav.pop();
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Uploaded: $fileName')),
          );
        },
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.bytes == null &&
        (file.path == null || !File(file.path!).existsSync())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file')),
        );
      }
      return;
    }

    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final plaintext = List<int>.from(bytes);
    final name = file.name;
    final ext = name.split('.').last.toLowerCase();
    final mimeType = ext == 'pdf'
        ? 'application/pdf'
        : ext == 'png'
            ? 'image/png'
            : ext == 'gif'
                ? 'image/gif'
                : ext == 'webp'
                    ? 'image/webp'
                    : 'image/jpeg';

    setState(() {
      _uploading = true;
      _progress = 0;
      _selectedFileName = name;
    });

    try {
      // 1. Encrypt locally with AES-256-GCM (MasterKey + random IV)
      setState(() => _progress = 0.2);
      final encrypted = await EncryptionService.instance.encrypt(
        Uint8List.fromList(plaintext),
      );
      final encryptedBytes = encrypted.combined;

      setState(() => _progress = 0.5);

      // 2. SHA-256 hash for tamper detection
      final hash = await Sha256().hash(encryptedBytes);
      final blobHash = hash.bytes;

      setState(() => _progress = 0.7);

      // 3. Auto-tag from filename
      final tags = tagFromFileName(name);
      final docId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
      final meta = DocumentMetadata(
        id: docId,
        name: name,
        mimeType: mimeType,
        uploadedAt: DateTime.now(),
        tags: tags.isNotEmpty ? tags : null,
        blobHash: blobHash,
      );

      // 4. Save to Firestore (blob stored as Base64 in document)
      await DocumentsRepository.instance.addDocument(meta, encryptedBytes);

      setState(() => _progress = 1.0);
      AutoLockHelper.instance.resetTimer();

      if (mounted) {
        _showEncryptionAnimation(context, name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _uploading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Upload Document',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Images & PDFs • Encrypted with AES-GCM • Stored in Firestore',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 24),
                      if (_uploading) ...[
                        if (_selectedFileName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _selectedFileName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ] else
                        OutlinedButton.icon(
                          onPressed: _pickAndUpload,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Choose File'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _LogsSection(logs: _logs),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _pickAndUpload,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class _LogsSection extends StatelessWidget {
  final List<DocumentAccessLog> logs;

  const _LogsSection({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
              Text(
                'No access logs yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Logs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...logs.take(10).map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.documentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${log.accessCount} time(s) • Last: ${log.lastAccessedText}',
                                style:
                                    Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
