# CyberFest Vault — Feature List (Judge Flex Sheet)

## 🔐 Authentication & Security

- **Password + PBKDF2 key derivation** — MasterKey derived from password + salt (100k iterations, SHA-256)
- **Biometric unlock** — Fingerprint/Face ID when available; password fallback on emulator
- **MasterKey only in memory** — Never persisted; wiped on logout, panic, or auto-lock
- **Zero-knowledge encryption** — Server (Firestore) stores only ciphertext; keys never leave device

## 🛡️ Duress & Panic

- **Duress PIN (9999)** — Opens empty fake vault instead of real content; wipes real keys
- **Panic button** — On Login and inside Vault; wipes MasterKey and redirects to login immediately
- **Auto-lock** — 3 min inactivity → keys wiped, redirect to login

## 📁 Document Storage

- **AES-256-GCM encryption** — Files encrypted before upload; IV + ciphertext + MAC
- **Firestore storage** — Encrypted blobs stored as Base64 in Firestore (no Firebase Storage)
- **SHA-256 tamper detection** — Hash verified before decrypt; aborts if file modified
- **Auto-tagging** — ID / Medical / Academic tags from filename keywords

## 🎨 UX & Polish

- **Encrypting animation** — Full-screen overlay when uploading: lock icon, "Encrypted & Secured"
- **Decrypting → Opening animation** — Two-phase overlay when viewing: "Decrypting…" → "Opening…" → file
- **Security status badge** — "🟢 Vault Secure" + "🔒 Zero-Knowledge Mode" at top of vault
- **Delete documents** — Per-document delete with confirmation
- **Search** — Filter documents by name
- **Portrait-only** — Locked orientation for mobile

## 📱 Platform

- **Screenshot blocking (Android)** — FLAG_SECURE prevents screenshots and screen recording
- **Modern theme** — Primary #2E3A59, accent #F5F6FA, rounded cards, subtle shadows

## 📋 Summary (One-liner for judges)

*Zero-knowledge encrypted vault with PBKDF2 + AES-256-GCM, duress mode, panic wipe, biometric unlock, tamper detection, and Firestore-backed storage.*
