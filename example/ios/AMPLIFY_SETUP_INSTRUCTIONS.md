# AWS Amplify Face Liveness Setup Instructions

This file contains instructions for setting up AWS Amplify Face Liveness SDK dependencies.

## Automatic Setup

The Skaletek KYC plugin has automatically:
- ✅ Copied AWS configuration files (amplifyconfiguration.json, awsconfiguration.json)
- ✅ Added configuration files to Xcode project
- ✅ Updated AppDelegate.swift with Amplify initialization

## Manual Swift Package Manager Setup Required

⚠️ **IMPORTANT**: You need to manually add the following Swift Package dependencies in Xcode:

### Step 1: Open your iOS project in Xcode
```bash
open ios/Runner.xcworkspace
```

### Step 2: Add Swift Package Dependencies
1. Go to **File > Add Package Dependencies...**
2. Add the following packages:

#### AWS Amplify Swift
- **URL**: `https://github.com/aws-amplify/amplify-swift`
- **Version**: `2.46.1` or later
- **Select these products**:
  - Amplify
  - AWSCognitoAuthPlugin

#### AWS Amplify UI Liveness
- **URL**: `https://github.com/aws-amplify/amplify-ui-swift-liveness`
- **Version**: `1.3.5` or later
- **Select the product**:
  - FaceLiveness

### Step 3: Build and Run
After adding these dependencies, you can build and run your iOS app with Face Liveness functionality.

---

*This setup ensures that the AWS Amplify Face Liveness SDK is properly integrated with your iOS app.*
