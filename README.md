# MindFlow 🌿

**MindFlow** is a modern, high-performance mindfulness, meditation, and wellness companion application built with **Flutter**, **Firebase**, and **Material 3**. It features adaptive time-based hero recommendations, customizable breathing exercises, sleep soundscapes, wellness tracking, and robust offline capabilities.

---

## 🚀 Features

- **Personalized Home Dashboard**: Dynamic greetings, daily progress tracking, streak counting, and mood logging.
- **Adaptive Hero Content**: Time-aware recommendations (Morning Focus, Midday Reset, Evening Calm, Deep Sleep).
- **Interactive Breathing Library**: Custom interactive animations (Calm Breath Clam Shell, Box Breathing, Wave Breath, Breath Cycle, Bubble Breathing).
- **Sleep Soundscapes**: High-quality audio playback with ambient sound mixer controls.
- **Offline & Caching Optimization**: Network image caching, pre-cached audio assets, and connection state management.
- **Enterprise Architecture**: MVVM architecture with Service Locator (`GetIt`), Repository encapsulation, and structured logging.
- **Security & Validation**: Firestore security rules with schema validation and role-based data access control.

---

## 🛠️ Architecture Overview

```
lib/
├── constants/         # App colors, strings, and configuration
├── exercises/         # Custom painters & interactive breathing animations
├── models/            # Immutable data models
├── repositories/      # Encapsulated data layer (Auth, Onboarding, User)
├── services/          # Low-level services (Logger, Firebase, Audio, Notifications)
├── viewmodels/        # MVVM business logic & state providers
├── views/             # Responsive UI screens & reusable widgets
└── main.dart          # App entry point & initialization
```

---

## 📦 Getting Started

### Prerequisites

- **Flutter SDK**: `>=3.12.2`
- **Dart SDK**: `>=3.0.0`
- **Firebase CLI**: Installed and configured for Android/iOS

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org/mindflow.git
   cd mindflow
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Quality Assurance

Run static analysis and test suites:

```bash
# Run static analysis
flutter analyze

# Run unit and widget tests
flutter test
```

---

## 🤖 CI/CD Automation

Continuous Integration is powered by **GitHub Actions** (`.github/workflows/ci.yml`). Every push and pull request automatically triggers:
- Dependency resolution
- Static lint checks (`flutter analyze`)
- Unit and widget test suite execution (`flutter test`)

---

## 📄 License

Copyright © 2026 MindFlow. All rights reserved.
