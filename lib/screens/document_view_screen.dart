import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../helpers/auto_lock_helper.dart';
import '../helpers/duress_helper.dart';
import '../services/documents_repository.dart';
import '../services/encryption_service.dart';
import '../services/master_key_service.dart';
import '../utils/app_navigator.dart';

/// Load encrypted blob (from Firestore blobBase64 or repository) → verify hash → decrypt → show.
class DocumentViewScreen extends StatefulWidget {
  static const routeName = '/document-view';

  final String documentId;
  final String documentName;
  final String mimeType;
  /// Encrypted blob as Base64 (from Firestore document).
  final String? blobBase64;
  /// Base64-encoded SHA-256 hash of blob for tamper check.
  final String? blobHashBase64;

  const DocumentViewScreen({
    super.key,
    required this.documentId,
    required this.documentName,
    required this.mimeType,
    this.blobBase64,
    this.blobHashBase64,
  });

  @override
  State<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen>
    with SingleTickerProviderStateMixin {
  Uint8List? _decryptedBytes;
  bool _loading = true;
  String? _error;
  /// 'decrypting' | 'opening' — for two-phase animation
  String _phase = 'decrypting';
  late AnimationController _decryptAnimController;
  late Animation<double> _contentFadeAnim;

  bool get _sessionExpired => !MasterKeyService.instance.isUnlocked;

  bool get _isImage => widget.mimeType.startsWith('image/');
  bool get _isPdf => widget.mimeType.contains('pdf');

  @override
  void initState() {
    super.initState();
    _decryptAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _contentFadeAnim = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_decryptAnimController);
    _loadAndDecrypt();
  }

  @override
  void dispose() {
    _decryptAnimController.dispose();
    _decryptedBytes = null;
    super.dispose();
  }

  Future<void> _loadAndDecrypt() async {
    if (_sessionExpired) {
      setState(() {
        _loading = false;
        _error = 'Session expired';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      Uint8List? encrypted;
      if (widget.blobBase64 != null) {
        encrypted = Uint8List.fromList(base64Decode(widget.blobBase64!));
      } else {
        encrypted = DocumentsRepository.instance.getEncryptedBlob(widget.documentId);
      }
      if (encrypted == null) {
        setState(() {
          _loading = false;
          _error = 'Document not found';
        });
        return;
      }

      // Tamper detection: verify SHA-256 hash before decrypt
      bool hashOk = true;
      if (widget.blobHashBase64 != null) {
        final storedHash = base64Decode(widget.blobHashBase64!);
        final computed = await Sha256().hash(encrypted);
        if (computed.bytes.length != storedHash.length) hashOk = false;
        else {
          for (var i = 0; i < storedHash.length; i++) {
            if (computed.bytes[i] != storedHash[i]) {
              hashOk = false;
              break;
            }
          }
        }
      } else {
        hashOk = await DocumentsRepository.instance.verifyBlobIntegrity(
          widget.documentId,
          encrypted,
        );
      }
      if (!hashOk && mounted) {
        setState(() {
          _loading = false;
          _error = 'Tamper warning: file may have been modified. Decryption aborted.';
        });
        return;
      }

      final decrypted = await EncryptionService.instance.decryptCombined(
        encrypted,
      );
      if (mounted) {
        DocumentsRepository.instance.recordAccess(
          widget.documentId,
          widget.documentName,
        );
        setState(() {
          _decryptedBytes = decrypted;
          _loading = false;
          _phase = 'opening';
        });
        AutoLockHelper.instance.resetTimer();
        // Brief "Opening..." phase, then show content
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() => _phase = 'done');
            _decryptAnimController.forward();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.documentName,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            tooltip: 'Panic — Wipe keys & lock',
            onPressed: () {
              DuressHelper.instance.panic();
              AutoLockHelper.instance.cancel();
              goToLogin();
            },
          ),
          if (_sessionExpired)
            IconButton(
              icon: const Icon(Icons.lock),
              tooltip: 'Session expired',
              onPressed: () => goToLogin(),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_sessionExpired) {
      return _LockOverlay(
        message: 'Session expired. Please log in again.',
      );
    }

    if (_loading || _phase == 'opening') {
      return _DecryptingAnimation(
        documentName: widget.documentName,
        phase: _phase,
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (_decryptedBytes == null || _phase != 'done') return const SizedBox.shrink();

    Widget content;
    if (_isImage) {
      content = InteractiveViewer(
        child: Center(
          child: Image.memory(
            _decryptedBytes!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      );
    } else if (_isPdf) {
      content = PdfViewerWidget(bytes: _decryptedBytes!);
    } else {
      content = Center(
        child: Text(
          'Preview not available for ${widget.mimeType}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return FadeTransition(
      opacity: _contentFadeAnim,
      child: content,
    );
  }
}

/// Decrypting state: full-screen overlay like upload — "Decrypting..." → "Opening..." → show file.
class _DecryptingAnimation extends StatefulWidget {
  final String documentName;
  final String phase; // 'decrypting' | 'opening'

  const _DecryptingAnimation({
    required this.documentName,
    required this.phase,
  });

  @override
  State<_DecryptingAnimation> createState() => _DecryptingAnimationState();
}

class _DecryptingAnimationState extends State<_DecryptingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _lockController;
  late AnimationController _shieldController;
  late Animation<double> _lockScale;
  late Animation<double> _shieldOpacity;

  @override
  void initState() {
    super.initState();
    _lockController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shieldController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _lockScale = Tween<double>(begin: 0.5, end: 1.15)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_lockController);
    _shieldOpacity = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_shieldController);
    _lockController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _shieldController.forward();
    });
  }

  @override
  void dispose() {
    _lockController.dispose();
    _shieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpening = widget.phase == 'opening';
    return Material(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _lockController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _shieldOpacity,
                      child: ScaleTransition(
                        scale: _lockScale,
                        child: Icon(
                          isOpening ? Icons.lock_open : Icons.lock,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  isOpening ? 'Opening…' : 'Decrypting…',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.documentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 4,
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockOverlay extends StatelessWidget {
  final String message;

  const _LockOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PDF viewer using pdfx.
class PdfViewerWidget extends StatefulWidget {
  final Uint8List bytes;

  const PdfViewerWidget({super.key, required this.bytes});

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  late PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(widget.bytes),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewPinch(
      controller: _controller,
    );
  }
}
