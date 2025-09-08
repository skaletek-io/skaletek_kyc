## 0.0.6
**Document Detection Logic Update** - Improved document detection reliability.

### 🐛 Bug Fixes
* **Document Detection**: Removed unnecessary success condition check that was preventing proper document detection
* **General**: Improved error handling and fallback behavior for document processing

---

## 0.0.4
**Cross-Platform Compatibility Release** - Enhanced Windows support and bug fixes.

## 0.0.3

**Bug Fix Release** - Various improvements and fixes.

### 🐛 Bug Fixes
* **Android**: Fixed build issues with release configurations
* **UI**: Fixed text overflow and layout overlapping issues
* **General**: Various minor bug fixes and improvements

---

## 0.0.2

**Bug Fix Release** - Fixed SvgPicture.network compilation error.

### 🐛 Bug Fixes
* **Logo Component**: Fixed `errorBuilder` parameter issue in `SvgPicture.network` that was causing compilation errors in Flutter SDK 3.8.1+

---

## 0.0.1

**Initial Release** - Complete KYC verification solution for Flutter applications.

### ✨ Features
* **Document Verification**: Support for passport, national ID, driver's license, and other identity documents
* **Face Liveness Detection**: Real-time biometric verification using AWS Amplify Face Liveness SDK
* **Camera Integration**: Live document capture with auto-detection and manual capture modes
* **File Upload Support**: Gallery and file-based document upload options
* **Customizable UI**: Branded verification experience with configurable colors, logos, and themes
* **Cross-Platform**: Full iOS and Android support with native integrations

### 🔧 Platform Support
* **Android**: Kotlin 2.0, Jetpack Compose, automated AWS Amplify configuration
* **iOS**: Swift 5.0, iOS 14.0+, automated setup via CocoaPods integration
* **Flutter**: Compatible with Flutter 3.8.1 and higher

### 🚀 Automation Features
* **Android**: Automated copying of AWS configuration files via Gradle tasks
* **iOS**: Automated Podfile integration for seamless setup without manual scripts
* **Configuration**: Auto-detection and setup of AWS Amplify Face Liveness dependencies

### 🛡️ Security & Infrastructure
* Enterprise-grade security with AWS infrastructure
* Secure session token-based authentication
* Real-time WebSocket communication for verification status
* Comprehensive error handling and user feedback

### 📚 Developer Experience
* Complete API documentation and usage examples
* Automated platform setup with minimal manual configuration
* Comprehensive README with step-by-step integration guides
* Example app demonstrating all plugin features

### 🐛 Bug Fixes
* **Logo Component**: Fixed `errorBuilder` parameter issue in `SvgPicture.network` that was causing compilation errors in Flutter SDK 3.8.1+
