# 💰 Savessa

<div align="center">
  
  ![Savessa Logo](https://via.placeholder.com/200x200.png?text=Savessa)
  
  ### Community Savings Made Simple
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.0.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
  [![Algorand](https://img.shields.io/badge/Algorand-000000?style=for-the-badge&logo=algorand&logoColor=white)](https://www.algorand.com/)
  [![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
  
</div>

## 📋 Table of Contents
- [Overview](#-overview)
- [Features](#-features)
- [Technology Stack](#-technology-stack)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Firebase Configuration](#-firebase-configuration)
- [Payment Integration](#-payment-integration)
- [Blockchain Features](#-blockchain-features)
- [UI/UX Design](#-uiux-design)
- [Monetization](#-monetization)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)

## 🌟 Overview

Savessa is a cutting-edge mobile app designed to revolutionize community-based savings groups. Developed by CharaD7, founder of CharaTech, Savessa is built with scalability and inclusivity in mind, combining intuitive design, advanced analytics, and blockchain transparency to empower users across Africa and beyond.

Starting in Ghana with plans to expand across Africa and globally, Savessa addresses the challenges faced by traditional community savings groups by providing a secure, transparent, and user-friendly platform for managing group savings and contributions.

## ✨ Features

### Core Functionality
- 👤 **User Registration & Authentication**
  - Secure login with email/phone verification
  - Admin and member role management
  - Profile customization

- 💵 **Savings Management**
  - Monthly savings input and tracking
  - Contribution history and logs
  - Receipt uploads and verification

- 👥 **Group Management**
  - Create and join savings groups
  - Invite members via shareable codes
  - Group rules and contribution settings

- 📊 **Analytics & Reporting**
  - Group-wide savings analytics
  - Personal savings progress tracking
  - Year-end summaries and reports
  - Visual dashboards with charts and milestones

- 🔔 **Smart Notifications**
  - Due date reminders
  - Missed payment alerts
  - Milestone celebrations
  - Group announcements

### Advanced Features
- 📱 **Offline Access**
  - Core functionality available in low-connectivity regions
  - Data synchronization when connection is restored

- 🌐 **Multi-language Support**
  - Initial support for English and French
  - Expandable to other African languages

- 🔒 **Enhanced Security**
  - Biometric authentication
  - End-to-end encryption for sensitive data
  - Secure transaction processing

## 🛠️ Technology Stack

Savessa is built using modern technologies to ensure reliability, scalability, and security:

- **Frontend**: Flutter for cross-platform mobile development
- **Backend**: Firebase for authentication and real-time features
- **Database**: PostgreSQL for relational data storage
- **Payments**: Flutterwave and Paystack integration
- **Blockchain**: Algorand for transparent transaction records
- **State Management**: Provider and Bloc patterns
- **Localization**: Easy Localization for multi-language support
- **Analytics**: Firebase Analytics and custom analytics dashboard
- **Storage**: Firebase Storage and local secure storage

## 🏗️ Architecture

Savessa follows a clean architecture approach with separation of concerns:

```
lib/
├── core/            # Core utilities, constants, and theme
├── features/        # Feature modules (auth, savings, groups, etc.)
├── shared/          # Shared widgets and services
├── models/          # Data models
├── services/        # API and service integrations
└── main.dart        # Application entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Firebase account
- Algorand development account

#### Platform-Specific Build Tools
Depending on which platform you're targeting, you'll need additional build tools:

**For Android:**
- Android SDK
- Android NDK

**For iOS/macOS:**
- Xcode
- CocoaPods

**For Linux:**
- Clang or GCC (C++ compiler)
- Ninja build system
- GTK development headers
- Other dependencies:
  ```bash
  sudo apt-get update
  sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
  ```

**For Windows:**
- Visual Studio with C++ build tools
- Windows 10 SDK
- CMake
- Ninja build system
  ```bash
  # Using chocolatey
  choco install cmake ninja visualstudio2019-workload-nativedesktop
  ```

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/CharaD7/savessa.git
   cd savessa
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Create a Firebase project
   - Add Android and iOS apps to your Firebase project  
   - Download and add the configuration files
   - **Configure Environment Variables**: Copy `.env.example` to `.env` and update with your Firebase credentials (see [Firebase Configuration](#-firebase-configuration) below)

4. Configure Algorand:
   - Set up Algorand development environment
   - Configure API keys in the app

5. Run the app:
   ```bash
   flutter run
   ```

## 🔥 Firebase Configuration

Savessa uses environment variables to store Firebase credentials securely. This approach improves security by keeping sensitive information out of version control and allows for different configurations across development, staging, and production environments.

### Setting Up Environment Variables

1. **Copy the example file**:
   ```bash
   cp .env.example .env
   ```

2. **Get your Firebase credentials**:
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Navigate to **Project Settings** (gear icon)
   - Scroll down to the **"Your apps"** section
   - For each platform (Web, Android, iOS, etc.), copy the respective configuration values

3. **Update your `.env` file** with the actual values:

```env
# Firebase Configuration
# Shared across all platforms
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_STORAGE_BUCKET=your-project-id.firebasestorage.app

# Platform-specific API Keys
FIREBASE_WEB_API_KEY=your-web-api-key
FIREBASE_ANDROID_API_KEY=your-android-api-key
FIREBASE_IOS_API_KEY=your-ios-api-key
FIREBASE_MACOS_API_KEY=your-macos-api-key
FIREBASE_WINDOWS_API_KEY=your-windows-api-key

# Platform-specific App IDs
FIREBASE_WEB_APP_ID=1:123456789:web:abcdef123456
FIREBASE_ANDROID_APP_ID=1:123456789:android:abcdef123456
FIREBASE_IOS_APP_ID=1:123456789:ios:abcdef123456
FIREBASE_MACOS_APP_ID=1:123456789:ios:abcdef123456  # Usually same as iOS
FIREBASE_WINDOWS_APP_ID=1:123456789:web:abcdef123456

# Web-specific configuration
FIREBASE_WEB_AUTH_DOMAIN=your-project-id.firebaseapp.com
FIREBASE_WEB_MEASUREMENT_ID=G-XXXXXXXXXX

# Windows-specific configuration
FIREBASE_WINDOWS_AUTH_DOMAIN=your-project-id.firebaseapp.com
FIREBASE_WINDOWS_MEASUREMENT_ID=G-YYYYYYYYYY

# iOS/macOS-specific configuration
FIREBASE_IOS_BUNDLE_ID=com.your-company.savessa
```

### Where to Find Each Value

#### From Firebase Console > Project Settings > Your Apps:

**Web App Configuration:**
- `FIREBASE_WEB_API_KEY` → `apiKey`
- `FIREBASE_WEB_APP_ID` → `appId`
- `FIREBASE_WEB_AUTH_DOMAIN` → `authDomain`
- `FIREBASE_WEB_MEASUREMENT_ID` → `measurementId`

**Android App Configuration:**
- `FIREBASE_ANDROID_API_KEY` → From `google-services.json` → `client[0].api_key[0].current_key`
- `FIREBASE_ANDROID_APP_ID` → From `google-services.json` → `client[0].client_info.mobilesdk_app_id`

**iOS App Configuration:**
- `FIREBASE_IOS_API_KEY` → From `GoogleService-Info.plist` → `API_KEY`
- `FIREBASE_IOS_APP_ID` → From `GoogleService-Info.plist` → `GOOGLE_APP_ID`
- `FIREBASE_IOS_BUNDLE_ID` → From `GoogleService-Info.plist` → `BUNDLE_ID`

**Shared Values:**
- `FIREBASE_PROJECT_ID` → Project ID (same across all platforms)
- `FIREBASE_MESSAGING_SENDER_ID` → Sender ID (same across all platforms)
- `FIREBASE_STORAGE_BUCKET` → Storage bucket (same across all platforms)

### Environment File Security

- ✅ **DO**: Keep `.env` file in your local development environment only
- ✅ **DO**: Use different `.env` files for different environments (dev, staging, prod)
- ✅ **DO**: Add `.env` to your `.gitignore` file (already done in this project)
- ❌ **DON'T**: Commit `.env` files to version control
- ❌ **DON'T**: Share `.env` files via email or messaging
- ❌ **DON'T**: Include real credentials in screenshots or documentation

### Validation

The app automatically validates your Firebase configuration on startup:

- ✅ **Success**: "Firebase environment configuration validated successfully"
- ❌ **Error**: Detailed error message showing which variables are missing or invalid

### Multiple Environments

For different environments, create separate `.env` files:

```bash
.env.development    # Local development
.env.staging        # Staging environment
.env.production     # Production environment
```

Then load the appropriate file:

```dart
// In main.dart, you can conditionally load different env files
await dotenv.load(fileName: '.env.${Environment.current}');
```

## 💳 Payment Integration

Savessa integrates with popular payment providers in Africa:

- **Flutterwave**: For mobile money and bank transfers in Ghana and other African countries
- **Paystack**: For additional payment options and wider coverage

These integrations allow users to:
- Make contributions directly from their mobile money accounts
- Set up recurring payments
- Receive payment confirmations and receipts
- Track all financial transactions securely

## ⛓️ Blockchain Features

Savessa leverages Algorand blockchain technology for:

- **Immutable Records**: Transparent and tamper-proof tracking of monthly contributions
- **End-of-Year Summaries**: Blockchain-verified annual reports
- **Smart Contracts**: Automated verification of savings milestones
- **Reward System**: Smart contract automation for savings goals and achievements

## 🎨 UI/UX Design

Savessa features a clean, intuitive interface designed with all users in mind:

- **Color Palette**:
  - Primary – Royal Purple (#6A0DAD): Suggests wealth, ambition, and wisdom
  - Accent – Metallic Gold (#FFD700): Signals premium quality and success
  - Contrast – Pure White (#FFFFFF): Clean backdrop for high readability
  - Dark Mode: Elegant dark theme with appropriate color adaptations

- **Theme Support**:
  - Light/Dark mode toggle for user preference
  - System theme detection for automatic adjustment
  - Persistent theme settings across app sessions

- **Accessibility**: Support for older users and those with limited tech experience
- **Progressive Complexity**: Simple interfaces that scale up as users become more familiar
- **Guided Onboarding**: Step-by-step tutorials for all features
- **Animations**: Engaging animations to enhance understanding and user experience

## 💼 Monetization

Savessa offers multiple revenue streams:

- **Tiered Subscription Plans**:
  - Free: Basic features with ads
  - Premium: Advanced features, no ads
  - Enterprise: Custom solutions for large groups

- **Transaction Fees**:
  - Small percentage on money transfers
  - Withdrawal fees (with transparent pricing)

- **Optional Advertising**:
  - Non-intrusive ads for free-tier users
  - Targeted financial service promotions

## 🗓️ Roadmap

- **Q3 2025**: Launch in Ghana with core features
- **Q4 2025**: Expand to Nigeria and Kenya
- **Q1 2026**: Add advanced blockchain features
- **Q2 2026**: Implement AI-powered savings recommendations
- **Q3 2026**: Expand to other African countries
- **Q4 2026**: Global expansion planning

## 🔧 Troubleshooting

### Common Issues

#### CMake Error: Unable to find Ninja build system

**Error Message:**
```
CMake Error: CMake was unable to find a build program corresponding to "Ninja". CMAKE_MAKE_PROGRAM is not set. You probably need to select a different build tool.
CMake Error: CMAKE_CXX_COMPILER not set, after EnableLanguage
Error: Unable to generate build files
```

**Solution:**
1. Install the Ninja build system and C++ compiler:
   - **Linux:** `sudo apt-get install ninja-build cmake clang`
   - **Windows:** `choco install ninja cmake` and install Visual Studio with C++ build tools
   - **macOS:** `brew install ninja cmake`

2. If you can't install Ninja, you can configure Flutter to use a different CMake generator:
   ```bash
   # For Linux/macOS
   export CMAKE_GENERATOR="Unix Makefiles"
   flutter run
   
   # For Windows
   set CMAKE_GENERATOR="Visual Studio 16 2019"
   flutter run
   ```

#### Flutter pub get fails with dependency conflicts

**Solution:**
1. Try running with the `--no-pub-get` flag first:
   ```bash
   flutter pub get --no-pub-get
   ```
2. If that doesn't work, try upgrading dependencies:
   ```bash
   flutter pub upgrade --major-versions
   ```
3. If issues persist, check the `pubspec.yaml` for conflicting dependencies

## 👥 Contributing

We welcome contributions to Savessa! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

Please read our [Contributing Guidelines](CONTRIBUTING.md) for more details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact

- **Developer**: CharaD7, Founder of CharaTech
- **Project Website**: [savessa.com](https://savessa.com)
- **Email**: info@savessa.com
- **Twitter**: [@savessaapp](https://twitter.com/savessaapp)
- **LinkedIn**: [Savessa](https://linkedin.com/company/savessa)
- **GitHub**: [CharaD7](https://github.com/CharaD7)

---

<div align="center">
  
  Made with ❤️ by CharaD7, Founder of CharaTech
  
  Copyright © 2025 CharaD7 (CharaTech). All rights reserved.
  
</div>