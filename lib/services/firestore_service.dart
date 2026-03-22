import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/document_metadata.dart';

/// Firestore: vault_docs/{userId}/documents/{documentId}
/// Fields: id, name, mimeType, uploadedAt, blobBase64, blobHash (base64), tags.
/// Encrypted blobs stored directly in Firestore as Base64 (optimized for small demo files <1MB).
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  static const _collectionVault = 'vault_docs';

  CollectionReference<Map<String, dynamic>> _userDocs(String userId) =>
      FirebaseFirestore.instance
          .collection(_collectionVault)
          .doc(userId)
          .collection('documents');

  /// Load all documents from Firestore (metadata + blobBase64), ordered by uploadedAt desc.
  Future<List<DocumentMetadata>> loadDocuments(String userId) async {
    final snapshot = await _userDocs(userId)
        .orderBy('uploadedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final d = doc.data();
      final uploadedAt = d['uploadedAt'] is Timestamp
          ? (d['uploadedAt'] as Timestamp).toDate()
          : DateTime.now();
      List<int>? blobHash;
      if (d['blobHash'] != null && d['blobHash'] is String) {
        blobHash = base64Decode(d['blobHash'] as String);
      }
      return DocumentMetadata(
        id: d['id'] as String? ?? doc.id,
        name: d['name'] as String? ?? 'Unknown',
        mimeType: d['mimeType'] as String? ?? 'application/octet-stream',
        uploadedAt: uploadedAt,
        tags: _toStringList(d['tags']),
        blobBase64: d['blobBase64'] as String?,
        blobHash: blobHash,
      );
    }).toList();
  }

  /// Alias for loadDocuments (keeps existing callers working).
  Future<List<DocumentMetadata>> loadDocumentMetadata(String userId) =>
      loadDocuments(userId);

  List<String>? _toStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  /// Write full document to Firestore (including encrypted blob as Base64).
  Future<void> writeDocument({
    required String userId,
    required DocumentMetadata metadata,
    required String blobBase64,
    required List<int> blobHash,
  }) async {
    await _userDocs(userId).doc(metadata.id).set({
      'id': metadata.id,
      'name': metadata.name,
      'mimeType': metadata.mimeType,
      'uploadedAt': Timestamp.fromDate(metadata.uploadedAt),
      'blobBase64': blobBase64,
      'blobHash': base64Encode(blobHash),
      'tags': metadata.tags ?? [],
    });
  }

  /// Delete document from Firestore.
  Future<void> deleteDocument(String userId, String documentId) async {
    await _userDocs(userId).doc(documentId).delete();
  }

  /// Alias for deleteDocument.
  Future<void> deleteMetadata(String userId, String documentId) =>
      deleteDocument(userId, documentId);
}
