/// Access log for a document: last opened, open count.
class DocumentAccessLog {
  final String documentId;
  final String documentName;
  final DateTime? lastAccessedAt;
  final int accessCount;

  const DocumentAccessLog({
    required this.documentId,
    required this.documentName,
    this.lastAccessedAt,
    this.accessCount = 0,
  });

  String get lastAccessedText {
    if (lastAccessedAt == null) return 'Never';
    final d = lastAccessedAt!;
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}
