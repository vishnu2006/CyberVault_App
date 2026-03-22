/// Auto-tag documents from filename keywords.
/// Tags: ID, Medical, Academic
List<String> tagFromFileName(String fileName) {
  final lower = fileName.toLowerCase();
  final tags = <String>[];

  // ID: passport, aadhaar, pan, license, voter, id card
  const idKeywords = [
    'id', 'passport', 'aadhaar', 'aadhar', 'pan', 'license', 'licence',
    'voter', 'identity', 'driving', 'dl '
  ];
  if (idKeywords.any((k) => lower.contains(k))) {
    tags.add('ID');
  }

  // Medical: hospital, prescription, doctor, health, medical, lab, report
  const medicalKeywords = [
    'medical', 'hospital', 'prescription', 'doctor', 'health', 'lab',
    'report', 'xray', 'x-ray', 'blood', 'diagnosis'
  ];
  if (medicalKeywords.any((k) => lower.contains(k))) {
    tags.add('Medical');
  }

  // Academic: marks, certificate, result, transcript, degree, academic
  const academicKeywords = [
    'marks', 'certificate', 'result', 'transcript', 'degree', 'academic',
    'marksheet', 'mark sheet', 'report card', 'diploma'
  ];
  if (academicKeywords.any((k) => lower.contains(k))) {
    tags.add('Academic');
  }

  return tags;
}
