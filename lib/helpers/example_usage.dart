/// Example usage of vault helpers in Upload and DocumentView screens.
///
/// --- UPLOAD SCREEN ---
/// ```dart
/// // 1. Pick file
/// final result = await FilePicker.platform.pickFiles(...);
/// final bytes = result.files.single.bytes;
///
/// // 2. Encrypt with AES-GCM (MasterKey + random IV)
/// final encrypted = await EncryptionService.instance.encrypt(Uint8List.fromList(bytes));
///
/// // 3. Optional: split into shards before upload (sharding placeholder)
/// // final shards = ShardingHelper.instance.split(encrypted.combined);
///
/// // 4. Save to Firestore (blob as Base64 in document)
/// await DocumentsRepository.instance.addDocument(
///   DocumentMetadata(...),
///   encrypted.combined,
/// );
///
/// // 6. Reset auto-lock timer
/// AutoLockHelper.instance.resetTimer();
/// ```
///
/// --- DOCUMENT VIEW SCREEN ---
/// ```dart
/// // 1. Check session
/// if (!MasterKeyService.instance.isUnlocked) {
///   // Show lock icon, prompt re-login
///   return LockOverlay(...);
/// }
///
/// // 2. Fetch encrypted blob (blobBase64 from Firestore doc)
/// final encrypted = base64Decode(metadata.blobBase64!);
///
/// // 3. Decrypt with MasterKey + IV
/// final decrypted = await EncryptionService.instance.decryptCombined(encrypted);
///
/// // 4. Display (image or PDF)
/// Image.memory(decrypted);
///
/// // 5. Auto-clear from memory on dispose
/// @override
/// void dispose() {
///   _decryptedBytes = null;
///   super.dispose();
/// }
///
/// // 6. Reset auto-lock timer
/// AutoLockHelper.instance.resetTimer();
/// ```
///
/// --- LOGIN / DUress ---
/// ```dart
/// if (DuressHelper.instance.isDuressPin(pin)) {
///   DuressHelper.instance.openFakeVault();
///   Navigator.pushReplacementNamed(context, VaultHomeFakeScreen.routeName);
/// } else if (validPin(pin)) {
///   await MasterKeyService.instance.deriveMasterKey(pin);
///   AutoLockHelper.instance.start(onLock: () => Navigator.pushReplacementNamed(context, LoginScreen.routeName));
///   Navigator.pushReplacementNamed(context, VaultHomeScreen.routeName);
/// }
/// ```
///
/// --- PANIC ---
/// ```dart
/// DuressHelper.instance.panic();
/// // Optionally: Navigator.pushReplacementNamed(context, LoginScreen.routeName);
/// ```
