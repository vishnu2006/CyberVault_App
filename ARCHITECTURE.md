# CyberFest Vault — Architecture & Workflow

## Overview

CyberFest Vault is a zero-knowledge document vault. Files are **encrypted on-device before any storage**. The server (Firebase) stores only ciphertext—keys never leave the device.

---

## 1. App Startup Flow

```
┌─────────────────┐
│   App Launch    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     No      ┌──────────────────┐
│ AuthGateScreen  │────────────►│ SetPasswordScreen│
│ (Check stored   │             │ (First-time)     │
│  password?)     │             └────────┬─────────┘
└────────┬────────┘                      │
         │ Yes                           │ Set password
         ▼                               │ Derive MasterKey
┌─────────────────┐                      │ Store salt + hash
│  LoginScreen    │◄─────────────────────┘
│ (Password +     │
│  Biometric)     │
└────────┬────────┘
         │ Success
         ▼
┌─────────────────┐
│ VaultHomeScreen │
│ (Document list) │
└─────────────────┘
```

---

## 2. First-Time Setup: Set Password

| Step | Action | Where | Details |
|------|--------|-------|---------|
| 1 | User enters password + confirm | SetPasswordScreen | Min 4 chars |
| 2 | Generate random salt | KeyDerivationHelper | 32 bytes, `Random.secure()` |
| 3 | Derive MasterKey | PBKDF2-HMAC-SHA256 | `password + salt`, 100k iterations, 32-byte output |
| 4 | Store MasterKey in memory | MasterKeyService | **Only in RAM**, never persisted |
| 5 | Store salt + verify hash | AuthStorageService | Salt + SHA-256(MasterKey) in SharedPreferences |
| 6 | Navigate to Vault | — | Auto-lock timer started |

**What is stored on disk:**
- `has_password_set`: boolean
- `vault_salt`: base64(salt)
- `vault_verify_hash`: base64(SHA256(MasterKey))

**What is NOT stored:**
- MasterKey
- Password

---

## 3. Login Flow

| Step | Action | Details |
|------|--------|---------|
| 1 | User enters password | LoginScreen |
| 2 | Duress check | If password is `9999` → open fake vault, wipe keys |
| 3 | Load salt | From AuthStorageService |
| 4 | Derive key | PBKDF2(password, salt) → keyBytes |
| 5 | Verify password | SHA256(keyBytes) vs stored hash |
| 6 | If invalid | Show "Invalid password", return |
| 7 | Store key in memory | MasterKeyService.setMasterKeyBytes(keyBytes) |
| 8 | Biometric (optional) | If available, prompt; if fails, still allow unlock |
| 9 | Start auto-lock | Timer resets on activity |
| 10 | Navigate to Vault | VaultHomeScreen |

---

## 4. Upload Flow (Encryption)

| Step | Action | Details |
|------|--------|---------|
| 1 | Pick file | FilePicker: images (jpg, png, gif, webp), PDF |
| 2 | Read raw bytes | `plaintext` = file content |
| 3 | Get MasterKey | From MasterKeyService (in memory) |
| 4 | Generate random IV | 12 bytes (AES-GCM nonce) |
| 5 | Encrypt | AES-256-GCM(plaintext, MasterKey, IV) |
| 6 | Combine format | `[IV (12B) \|\| ciphertext \|\| MAC (16B)]` |
| 7 | Upload | StorageService → Firebase Storage (placeholder) |
| 8 | Save metadata | DocumentMetadata (name, mimeType, id, uploadedAt) |
| 9 | Add to repository | DocumentsRepository (in-memory demo) |
| 10 | Show "Encrypted & Secured" | EncryptionSuccessAnimation overlay |

**Access logs:** Each document gets an access log (last accessed, open count). Logs appear on the Upload screen.

**Encryption format on disk/cloud:**
```
[IV: 12 bytes][Ciphertext: variable][MAC: 16 bytes]
```
- IV and MAC are needed for decryption; they are stored with the ciphertext.

---

## 5. Document View Flow (Decryption)

| Step | Action | Details |
|------|--------|---------|
| 1 | User taps document | VaultHomeScreen → DocumentViewScreen |
| 2 | Show "Decrypting and processing..." | Card with lock-open icon and spinner |
| 3 | Fetch encrypted blob | DocumentsRepository or Firebase Storage |
| 4 | Parse combined format | IV = first 12 bytes, MAC = last 16 bytes |
| 5 | Get MasterKey | From MasterKeyService (in memory) |
| 6 | Decrypt | AES-256-GCM decrypt(ciphertext, MasterKey, IV, MAC) |
| 7 | Plaintext in memory | `_decryptedBytes` |
| 8 | Display | Image.memory() or PdfViewer |
| 9 | Record access | Log: lastAccessed, accessCount++ |
| 10 | On dispose | Clear `_decryptedBytes` from memory |

---

## 6. Key Storage (Critical)

| Item | Stored? | Location |
|------|---------|----------|
| MasterKey | **NO** | Only in RAM (MasterKeyService) |
| Password | **NO** | Never stored |
| Salt | Yes | SharedPreferences |
| Verify hash | Yes | SharedPreferences (SHA256 of MasterKey) |

**MasterKey lifecycle:**
1. Created: after password verification on login
2. Held in: `MasterKeyService._masterKeyBytes`
3. Cleared on: Panic, logout, auto-lock timeout

---

## 7. Auto-Lock

| Event | Action |
|-------|--------|
| User inactive X minutes | AutoLockHelper calls MasterKeyService.wipe() |
| Reset timer on | Vault open, document view, upload |
| Cancel timer on | Logout |

---

## 8. Duress Mode

| Trigger | Action |
|---------|--------|
| Password = `9999` | Open VaultHomeFake (empty vault), wipe real key |
| Panic button | Wipe MasterKey, show "Session wiped" |

---

## 9. Folder Structure

```
lib/
├── main.dart
├── screens/
│   ├── auth_gate_screen.dart
│   ├── set_password_screen.dart
│   ├── login_screen.dart
│   ├── vault_home_screen.dart
│   ├── vault_home_fake_screen.dart
│   ├── upload_screen.dart
│   └── document_view_screen.dart
├── services/
│   ├── auth_storage_service.dart    # Salt, verify hash
│   ├── master_key_service.dart      # In-memory MasterKey
│   ├── encryption_service.dart      # AES-GCM encrypt/decrypt
│   ├── storage_service.dart         # Firebase Storage placeholder
│   ├── documents_repository.dart    # Metadata + encrypted blobs
│   └── firestore_service.dart       # Firestore placeholder
├── models/
│   └── document_metadata.dart
├── helpers/
│   ├── key_derivation_helper.dart   # PBKDF2
│   ├── auto_lock_helper.dart
│   ├── duress_helper.dart
│   └── sharding_helper.dart         # Placeholder
└── widgets/
    ├── encryption_success_animation.dart
    └── decrypting_overlay.dart
```

---

## 10. Security Model

- **Zero-knowledge:** Server only sees ciphertext
- **Client-side encryption:** Before upload
- **Key derivation:** PBKDF2 100k iterations
- **Cipher:** AES-256-GCM with random IV per file
- **Integrity:** GCM MAC per ciphertext (TODO: SHA-256 file hash)

---

## 11. Placeholders (TODO)

- Firebase Auth, Firestore, Storage
- Sharding: split 1 file → 3 shards
- SHA-256 integrity hash, tamper detection
