# QR Hub — Premium QR Scanner & Generator

QR Hub is a modern, premium, dark-themed Flutter application designed for seamless QR code scanning and generation. Built with a sleek dashboard and fluid user feedback, it provides an intuitive interface to capture or create QR codes with zero friction.

---

## 🌟 Key Features

### 🔍 Real-Time QR Scanner
- **Active Scanning Window**: Centered viewport with corner guides to focus scanning.
- **Sweeping Laser Indicator**: A smooth, glowing neon-laser animation that runs across the scanning window.
- **Instant Controls**: Easily toggle the flashlight or switch between front and back cameras directly from the overlay.
- **Rich Action Bottom Sheet**: Displays detected contents immediately, classifying links versus plain text.
- **Context Actions**:
  - **Copy**: Copy content to clipboard in a single tap.
  - **Share**: Pass text or URLs to other apps natively.
  - **Open Link**: Launches scanned web links instantly in external browsers.

### ✍️ Real-Time QR Generator
- **Instant Rendering**: Generates high-fidelity QR codes dynamically as you type.
- **Color Customization**: The QR code is automatically color-optimized to fit the app's premium aesthetics.
- **Quick Sharing**: Share generated QR codes/text straight from the interface.
- **Clear Input**: One-tap text clear action.

---

## 🛠️ Tech Stack & Dependencies

The app uses the following high-performance packages:
*   **[mobile_scanner](https://pub.dev/packages/mobile_scanner)**: Fast and power-efficient mobile scanner using CameraX (Android) and AVFoundation (iOS).
*   **[qr_flutter](https://pub.dev/packages/qr_flutter)**: Premium widget for rendering static or dynamic QR codes.
*   **[url_launcher](https://pub.dev/packages/url_launcher)**: Opens web links and custom URI schemes externally.
*   **[share_plus](https://pub.dev/packages/share_plus)**: Implements native sharing dialogs.

---

## 🚀 Getting Started

### Prerequisites
Make sure you have [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system.

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Prem-Agravat/QR_scanner.git
   ```
2. Navigate into the project directory:
   ```bash
   cd qrcode_generator
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```

### Running the App
- Run on an emulator or physical device:
   ```bash
   flutter run
   ```

---

## 🔒 Permissions Configuration

The application requires camera access to scan QR codes:

### Android
Permissions are configured in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS
Permissions are configured in `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes.</string>
```

---

## 🧪 Testing

The project contains automated tests verifying the main user flow. To run tests, execute:
```bash
flutter test
```
