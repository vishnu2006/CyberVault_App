import 'package:flutter/material.dart' show IconData, Icons;

/// Document metadata for vault list display.
/// Tags: ID, Medical, Academic (auto-detected from filename).
/// blobBase64: Encrypted blob stored in Firestore as Base64.
/// blobHash: SHA-256 hash bytes for tamper detection (optional).
class DocumentMetadata {
  final String id;
  final String name;
  final String mimeType; // 'application/pdf', 'image/jpeg', etc.
  final DateTime uploadedAt;
  final List<String>? tags;
  /// Encrypted blob as Base64 (stored in Firestore).
  final String? blobBase64;
  /// SHA-256 hash of encrypted blob for integrity check.
  final List<int>? blobHash;

  const DocumentMetadata({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.uploadedAt,
    this.tags,
    this.blobBase64,
    this.blobHash,
  });

  List<String> get tagsOrEmpty => tags ?? const [];

  bool get isPdf => mimeType.contains('pdf');
  bool get isImage =>
      mimeType.startsWith('image/');

  IconData get icon {
    if (isPdf) return Icons.picture_as_pdf;
    if (isImage) return Icons.image;
    return Icons.description;
  }
}
