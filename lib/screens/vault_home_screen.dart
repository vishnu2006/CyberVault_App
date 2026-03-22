import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../helpers/auto_lock_helper.dart';
import '../helpers/duress_helper.dart';
import '../models/document_metadata.dart';
import '../services/documents_repository.dart';
import '../services/firestore_service.dart';
import '../services/master_key_service.dart';
import '../utils/app_navigator.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/secure_session_banner.dart';
import 'document_view_screen.dart';
import 'login_screen.dart';
import 'upload_screen.dart';
import 'settings_screen.dart';

class VaultHomeScreen extends StatefulWidget {
  static const routeName = '/vault-home';

  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen>
    with SingleTickerProviderStateMixin {
  List<DocumentMetadata> _documents = [];
  List<DocumentMetadata> _filteredDocuments = [];
  String _searchQuery = '';
  bool _loading = true;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  static const _userId = 'current_user'; // TODO: from Firebase Auth

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_animationController!);
    
    _loadDocuments();
    AutoLockHelper.instance.resetTimer();
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _loading = true);
    try {
      final docs =
          await DocumentsRepository.instance.loadMetadata(_userId);
      if (mounted) {
        setState(() {
          _documents = docs;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  Future<void> _deleteDocument(DocumentMetadata meta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
          'Permanently delete "${meta.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await FirestoreService.instance.deleteDocument(_userId, meta.id);
      DocumentsRepository.instance.removeDocument(meta.id);
      if (mounted) {
        await _loadDocuments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted: ${meta.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredDocuments = List.from(_documents);
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredDocuments = _documents
          .where((d) => d.name.toLowerCase().contains(q))
          .toList();
    }
  }

  void _showFeaturesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'CyberFest Vault — Features',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.lock,
                title: 'Zero-knowledge encryption',
                desc: 'AES-256-GCM, PBKDF2 key derivation, MasterKey only in memory',
              ),
              _FeatureItem(
                icon: Icons.fingerprint,
                title: 'Biometric unlock',
                desc: 'Fingerprint/Face ID when available',
              ),
              _FeatureItem(
                icon: Icons.warning_amber,
                title: 'Duress & panic',
                desc: 'Duress PIN (9999) → fake vault; Panic button → wipe keys & lock',
              ),
              _FeatureItem(
                icon: Icons.timer,
                title: 'Auto-lock',
                desc: '3 min inactivity → keys wiped, redirect to login',
              ),
              _FeatureItem(
                icon: Icons.verified_user,
                title: 'Tamper detection',
                desc: 'SHA-256 hash verified before decrypt',
              ),
              _FeatureItem(
                icon: Icons.screenshot_monitor,
                title: 'Screenshot blocking',
                desc: 'Android FLAG_SECURE',
              ),
              _FeatureItem(
                icon: Icons.cloud,
                title: 'Firestore storage',
                desc: 'Encrypted blobs as Base64 in Firestore',
              ),
              _FeatureItem(
                icon: Icons.animation,
                title: 'Encrypting / Decrypting animations',
                desc: 'Full-screen overlay during upload and view',
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          // Secure session banner at top
          const SecureSessionBanner(),
          
          // Modern AppBar with glassmorphism effect
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Secure Vault',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.settings_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      tooltip: 'Settings',
                      onPressed: () => Navigator.of(context).pushNamed(SettingsScreen.routeName),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.info_outline_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      tooltip: 'Features',
                      onPressed: () => _showFeaturesSheet(context),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      tooltip: 'Panic — Wipe keys & lock',
                      onPressed: () {
                        DuressHelper.instance.panic();
                        AutoLockHelper.instance.cancel();
                        goToLogin();
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.logout_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      tooltip: 'Logout',
                      onPressed: () {
                        MasterKeyService.instance.wipe();
                        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Main content area
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController ?? const AlwaysStoppedAnimation(0),
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1),
                  child: Column(
                    children: [
                      // Enhanced security status badge with glassmorphism
                      GlassmorphismCard(
                        margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        padding: const EdgeInsets.all(20),
                        opacity: 0.05,
                        blur: 12,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: Color(0xFF0F172A),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Vault Secured',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.primary,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '🔒 Zero-Knowledge Encryption Active',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                          letterSpacing: 0.25,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Enhanced search bar with glassmorphism
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: GlassmorphismCard(
                          opacity: 0.08,
                          blur: 15,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search documents...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _applyFilter();
                              });
                            },
                          ),
                        ),
                      ),
                      
                      // Document list with enhanced loading
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadDocuments,
                          color: Theme.of(context).colorScheme.primary,
                          child: _loading
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: CircularProgressIndicator(
                                          color: Theme.of(context).colorScheme.primary,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Loading secure documents...',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                )
                              : _filteredDocuments.isEmpty
                                  ? ListView(
                                      children: [
                                        SizedBox(
                                          height: MediaQuery.of(context).size.height * 0.4,
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GlassmorphismCard(
                                                  opacity: 0.05,
                                                  blur: 12,
                                                  padding: const EdgeInsets.all(24),
                                                  child: Icon(
                                                    Icons.folder_open_rounded,
                                                    size: 64,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                Text(
                                                  'No Documents Yet',
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: Theme.of(context).colorScheme.onSurface,
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Upload your first secure document',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                                      itemCount: _filteredDocuments.length,
                                      itemBuilder: (context, index) {
                                        final doc = _filteredDocuments[index];
                                        return _DocumentCard(
                                          metadata: doc,
                                          index: index,
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => DocumentViewScreen(
                                                documentId: doc.id,
                                                documentName: doc.name,
                                                mimeType: doc.mimeType,
                                                blobBase64: doc.blobBase64,
                                                blobHashBase64: doc.blobHash != null
                                                    ? base64Encode(doc.blobHash!)
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          onDelete: () => _deleteDocument(doc),
                                        );
                                      },
                                    ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context)
              .pushNamed(UploadScreen.routeName)
              .then((_) => _loadDocuments()),
          icon: const Icon(Icons.cloud_upload_rounded),
          label: const Text('Upload'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.background,
        ),
      ),
    );
  }
}

class _DocumentCard extends StatefulWidget {
  final DocumentMetadata metadata;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int index;

  const _DocumentCard({
    required this.metadata,
    required this.onTap,
    this.onDelete,
    required this.index,
  });

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);
        
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_controller);
        
    _slideAnimation = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);
    
    // Stagger animation based on widget index for cascade effect
    Future.delayed(Duration(milliseconds: 100 * (widget.index % 5)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metadata = widget.metadata;
    final dateStr =
        '${metadata.uploadedAt.day}/${metadata.uploadedAt.month}/${metadata.uploadedAt.year}';
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: GlassmorphismCard(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            opacity: 0.06,
            blur: 12,
            onTap: widget.onTap,
            child: Row(
              children: [
                // Enhanced icon container with glow
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    metadata.icon ?? Icons.insert_drive_file_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Document info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metadata.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.25,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                      if (metadata.tagsOrEmpty.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: metadata.tagsOrEmpty.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Actions with neon glow buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onDelete != null)
                      NeonGlowButton(
                        onPressed: widget.onDelete,
                        glowColor: Theme.of(context).colorScheme.error,
                        borderRadius: 10,
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.25,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        letterSpacing: 0.25,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
