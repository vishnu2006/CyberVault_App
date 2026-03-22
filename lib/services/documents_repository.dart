import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../models/document_access_log.dart';
import '../models/document_metadata.dart';
import 'firestore_service.dart';

/// Repository: Firestore as source of truth. Encrypted blobs stored as Base64 in Firestore.
/// In-memory cache for access logs and optional blob lookup.
class DocumentsRepository {
  DocumentsRepository._();
  static final DocumentsRepository instance = DocumentsRepository._();

  static const _userId = 'current_user'; // TODO: from Firebase Auth

  final Map<String, DocumentAccessLog> _accessLogs = {};
  final Map<String, DocumentMetadata> _metadataCache = {};

  List<DocumentMetadata> get documents => List.unmodifiable(_metadataCache.values);

  /// Add document: write to Firestore (encrypted blob as Base64) and update cache.
  Future<void> addDocument(DocumentMetadata meta, Uint8List encryptedBytes) async {
    final hash = await Sha256().hash(encryptedBytes);
    final blobBase64 = base64Encode(encryptedBytes);
    await FirestoreService.instance.writeDocument(
      userId: _userId,
      metadata: meta,
      blobBase64: blobBase64,
      blobHash: hash.bytes,
    );
    _metadataCache[meta.id] = DocumentMetadata(
      id: meta.id,
      name: meta.name,
      mimeType: meta.mimeType,
      uploadedAt: meta.uploadedAt,
      tags: meta.tags,
      blobBase64: blobBase64,
      blobHash: hash.bytes,
    );
    _accessLogs[meta.id] = DocumentAccessLog(
      documentId: meta.id,
      documentName: meta.name,
    );
  }

  /// Get encrypted blob from cache (populated when loading from Firestore).
  /// Returns null if not in cache; caller should use blobBase64 from metadata when available.
  Uint8List? getEncryptedBlob(String documentId) {
    final meta = _metadataCache[documentId];
    if (meta?.blobBase64 == null) return null;
    return Uint8List.fromList(base64Decode(meta!.blobBase64!));
  }

  List<int>? getBlobHash(String documentId) => _metadataCache[documentId]?.blobHash;

  /// Verify blob integrity. Returns true if hash matches.
  Future<bool> verifyBlobIntegrity(String documentId, Uint8List blob) async {
    final stored = _metadataCache[documentId]?.blobHash;
    if (stored == null) return true;
    final computed = await Sha256().hash(blob);
    if (computed.bytes.length != stored.length) return false;
    for (var i = 0; i < stored.length; i++) {
      if (computed.bytes[i] != stored[i]) return false;
    }
    return true;
  }

  void recordAccess(String documentId, String documentName) {
    final existing = _accessLogs[documentId];
    final now = DateTime.now();
    _accessLogs[documentId] = DocumentAccessLog(
      documentId: documentId,
      documentName: documentName,
      lastAccessedAt: now,
      accessCount: (existing?.accessCount ?? 0) + 1,
    );
  }

  List<DocumentAccessLog> get accessLogs {
    final list = _accessLogs.values.toList();
    list.sort((a, b) =>
        (b.lastAccessedAt ?? DateTime(0))
            .compareTo(a.lastAccessedAt ?? DateTime(0)));
    return list;
  }

  /// Load documents from Firestore and populate cache.
  Future<List<DocumentMetadata>> loadMetadata(String userId) async {
    final docs = await FirestoreService.instance.loadDocuments(userId);
    _metadataCache.clear();
    for (final d in docs) {
      _metadataCache[d.id] = d;
    }
    return docs;
  }

  /// Remove document from cache (after delete in Firestore).
  void removeDocument(String documentId) {
    _metadataCache.remove(documentId);
    _accessLogs.remove(documentId);
  }
}
