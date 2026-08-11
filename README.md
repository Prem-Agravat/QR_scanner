📱 QR Hub — Premium QR Scanner & Generator

QR Hub is a modern Flutter application that combines QR code scanning and generation in one simple and intuitive app. It features a premium dark-themed interface, real-time QR scanning, animated scanner feedback, dynamic QR generation, and convenient actions for sharing, copying, and opening scanned content.

---

✨ Features

🔍 QR Scanner

- Real-time QR code scanning using the device camera.
- Focused scanning area with corner indicators.
- Animated scanning laser for visual feedback.
- Flashlight toggle for low-light environments.
- Switch between front and rear cameras.
- Instantly displays detected QR content.
- Automatically identifies links and text.
- Copy scanned content with one tap.
- Share scanned content with other apps.
- Open detected URLs directly in the browser.

✍️ QR Generator

- Generate QR codes instantly from entered text or URLs.
- Live QR preview while typing.
- Clean and responsive QR display.
- Share generated QR content easily.
- Clear input with a single tap.
- Simple and fast generation workflow.

🎨 User Interface

- Premium dark-themed design.
- Clean and modern dashboard.
- Smooth animations and transitions.
- Responsive mobile layout.
- Interactive buttons and bottom sheets.
- Clear visual feedback for user actions.

---

🛠️ Tech Stack

- Flutter — Cross-platform mobile application framework.
- Dart — Programming language.
- mobile_scanner — Real-time QR and barcode scanning.
- qr_flutter — QR code generation and rendering.
- url_launcher — Opening detected URLs.
- share_plus — Native sharing functionality.

---

📦 Dependencies

- "mobile_scanner" (https://pub.dev/packages/mobile_scanner)
- "qr_flutter" (https://pub.dev/packages/qr_flutter)
- "url_launcher" (https://pub.dev/packages/url_launcher)
- "share_plus" (https://pub.dev/packages/share_plus)

---

🚀 Getting Started

Prerequisites

Make sure you have the following installed:

- Flutter SDK
- Dart SDK
- Git
- Android Studio or VS Code
- Android Emulator or a physical device

Installation

1. Clone the repository:

git clone https://github.com/Prem-Agravat/QR_scanner.git

2. Navigate to the project:

cd QR_scanner

3. Install dependencies:

flutter pub get

4. Run the application:

flutter run

---

🔒 Permissions

The QR scanner requires access to the device camera.

Android

Add camera permission in:

android/app/src/main/AndroidManifest.xml

<uses-permission android:name="android.permission.CAMERA" />

iOS

Add camera usage description in:

ios/Runner/Info.plist

<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes.</string>

---

📱 How It Works

Scan a QR Code

1. Open the scanner.
2. Allow camera access.
3. Point the camera at a QR code.
4. QR Hub automatically detects the code.
5. View the scanned result.
6. Copy, share, or open the content.

Generate a QR Code

1. Open the QR generator.
2. Enter text or a URL.
3. The QR code is generated automatically.
4. Preview the generated QR code.
5. Share the QR code or content.

---

🧪 Testing

Run the Flutter test suite with:

flutter test

Run static analysis with:

flutter analyze

---

🔮 Future Improvements

- Scan history
- Gallery-based QR scanning
- Save generated QR codes
- Custom QR colors and styles
- QR logo support
- Favorite QR codes
- Light and dark themes
- Export QR codes as images
- Additional QR and barcode formats

---

📄 License

This project is created for learning and development purposes.

---

👨‍💻 Author

Prem Agravat

Computer Engineering Student | Flutter & Web Developer

- GitHub: https://github.com/Prem-Agravat
- LinkedIn: https://www.linkedin.com/in/prem-agravat/

---

⭐ If you find QR Hub useful, consider giving the repository a star.
