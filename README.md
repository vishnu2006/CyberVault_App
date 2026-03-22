# 🏆 CyberVault - Secure Document Storage App

**🎯 Hackathon Achievement: We secured 2nd place among 110+ teams at the nation-level CyberFest Hackathon, winning a ₹12,000 cash prize and presenting our solution on stage in front of 500+ students and judges!**

A premium Flutter application providing secure document storage with biometric authentication and zero-knowledge encryption. CyberVault ensures your sensitive documents remain private and accessible only to you.

## 🌟 Features

### 🔐 Security & Authentication
- **Biometric Authentication** - Fingerprint and Face ID support
- **Master Password Protection** - AES-256 encrypted password system
- **Zero-Knowledge Architecture** - Your data never leaves your device unencrypted
- **Duress PIN System** - Emergency access with fake vault mode
- **Auto-Lock Functionality** - Automatic session timeout for security

### 📱 Premium User Experience
- **Glassmorphism Design** - Modern glass-morphic UI with blur effects
- **Neon Glow Animations** - Smooth, premium visual feedback
- **Cross-Platform Support** - Android, iOS, Web, Linux, macOS, Windows
- **Responsive Design** - Optimized for all screen sizes
- **Dark Theme** - Premium dark color scheme throughout

### 📄 Document Management
- **Secure Upload** - Encrypt documents before storage
- **Cloud Sync** - Firebase backend with end-to-end encryption
- **Document Viewer** - Built-in viewer for multiple file types
- **Search & Filter** - Find documents quickly and efficiently
- **Tagging System** - Organize documents with custom tags

## 🛠 Tech Stack

### Frontend
- **Flutter 3.x** - Cross-platform UI framework
- **Dart** - Programming language
- **Material 3** - Modern design system
- **Local Authentication** - Biometric SDK integration

### Backend & Services
- **Firebase Authentication** - User management
- **Firebase Firestore** - NoSQL database
- **Firebase Storage** - Cloud file storage
- **Cryptography Package** - AES-256 encryption

### Security
- **PBKDF2 Key Derivation** - Secure password hashing
- **AES-256 Encryption** - Military-grade encryption
- **Biometric Authentication** - Local device security
- **Zero-Knowledge Proof** - Privacy-first architecture

## 🚀 Installation

### Prerequisites
- Flutter SDK 3.0 or higher
- Dart SDK compatible with Flutter version
- Firebase account (for backend services)
- Physical device with biometric sensors (recommended)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/vishnu2006/CyberVault_App.git
   cd CyberVault_App
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android and iOS apps to your Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place config files in respective platform folders
   - Enable Authentication, Firestore, and Storage services

4. **Run the application**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Set `minSdkVersion` to 21 or higher in `android/app/build.gradle`
- Enable biometric authentication in device settings

#### iOS
- Set `deployment target` to iOS 12.0 or higher
- Add biometric permissions to `Info.plist`

## 📱 Screenshots

### Authentication Flow
- [Login Screen] - Biometric and password authentication
- [Set Password Screen] - Initial password setup
- [Settings Screen] - Biometric toggle and preferences

### Main Application
- [Vault Home] - Document overview with search
- [Document Upload] - Secure file upload interface
- [Document Viewer] - Encrypted document viewing
- [Security Features] - Biometric prompts and security indicators

*Note: Screenshots will be added here showcasing the premium UI design*

## 🔧 Configuration

### Firebase Rules
Configure Firestore and Storage security rules to ensure proper access control:

```javascript
// Firestore Rules Example
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Environment Setup
- Configure Firebase project settings
- Set up authentication providers
- Configure storage security rules
- Enable appropriate Firebase services

## 🚀 Future Improvements

### Enhanced Security
- [ ] End-to-end encrypted chat functionality
- [ ] Two-factor authentication (2FA)
- [ ] Hardware security key support
- [ ] Advanced audit logging

### User Experience
- [ ] Document sharing with encrypted links
- [ ] Collaborative vault features
- [ ] Advanced search with AI tagging
- [ ] Offline mode with sync capabilities

### Platform Expansion
- [ ] Progressive Web App (PWA) support
- [ ] Wear OS companion app
- [ ] Desktop application enhancements
- [ ] API for third-party integrations

## 🏗 Architecture

The application follows a clean architecture pattern with separation of concerns:

```
lib/
├── screens/           # UI screens and pages
├── services/          # Business logic and API calls
├── widgets/           # Reusable UI components
├── models/            # Data models and entities
├── helpers/           # Utility functions and helpers
└── utils/             # Common utilities
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Hackathon Achievement

**🎯 CyberFest Hackathon 2024 - 2nd Place Winner**

- **Competition**: 110+ teams nationwide
- **Prize**: ₹12,000 cash award
- **Presentation**: Live demo in front of 500+ students and industry judges
- **Innovation**: Recognized for exceptional security implementation and user experience

## 📞 Contact

- **Developer**: Vishnu
- **GitHub**: [@vishnu2006](https://github.com/vishnu2006)
- **Project**: [CyberVault_App](https://github.com/vishnu2006/CyberVault_App)

---

**Built with ❤️ using Flutter and Firebase**
