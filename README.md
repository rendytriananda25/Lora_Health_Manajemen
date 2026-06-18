# Lora Health Management

A comprehensive health and fitness tracking mobile application built with Flutter. The app focuses on personalized workout routines, GPS-based activity tracking, real-time nutrition management, and gamification to encourage a healthy lifestyle.

Developed with a strict adherence to **Clean Architecture** principles to ensure scalability, testability, and maintainability.

## 📱 Screenshots
> **Note:** Replace these placeholder links with actual images of your app before publishing your CV.
> 
> | Dashboard | GPS Tracking | Gamification |
> |:---:|:---:|:---:|
> | <img src="https://via.placeholder.com/250x500.png?text=Dashboard" width="200"/> | <img src="https://via.placeholder.com/250x500.png?text=Map+Tracking" width="200"/> | <img src="https://via.placeholder.com/250x500.png?text=Badges" width="200"/> |

## ✨ Key Features
- **Smart Workout Generation:** Progressive workout routines (Home Workout, Basketball, etc.) adapted to the user's fitness level, goal, and week progression.
- **GPS Activity Tracking:** Real-time location tracking for running and cycling using foreground services, equipped with anti-drift and noise-filtering algorithms.
- **Nutrition Management:** Daily calorie tracking and food recommendations synchronized with Firebase.
- **Health Metrics:** Interactive BMI calculator and historical weight tracking charts.
- **Gamification System:** Badge achievements, leveling up, and visual progress tracking to maintain user engagement.
- **Localization (i18n):** Multi-language support (English, Indonesian, Japanese, Spanish).
- **Admin CMS:** Built-in hidden admin mode to synchronize local master data with the cloud database.

## 🏗 Architecture
This project implements **Clean Architecture** (Domain-Driven Design), dividing the codebase into decoupled layers:
1. **Presentation:** UI and State Management (`Provider`).
2. **Domain:** Business logic (`UseCases`) and core business objects (`Entities`).
3. **Data:** External API calls, Firebase interactions (`DataSources`), and data parsing (`Models`).

This separation of concerns ensures that the core business logic remains independent of UI frameworks and external data sources.

## 🛠 Tech Stack
- **Framework:** Flutter SDK (^3.8.1)
- **Language:** Dart
- **State Management:** Provider
- **Backend (BaaS):** Firebase (Authentication, Realtime Database)
- **Location Services:** Geolocator, LatLong2, Flutter Map
- **Background Processes:** Flutter Background, Flutter Local Notifications
- **External APIs:** OpenWeatherMap API (for outdoor workout recommendations)

## ⚙️ Installation & Setup

### Prerequisites
- Flutter SDK installed
- Android Studio / VS Code
- A Firebase project with Authentication and Realtime Database enabled

### Steps to Run
1. **Clone the repository:**
   ```bash
   git clone https://github.com/rendytriananda25/Lora_Health_Manajemen.git
   cd Lora_Health_Manajemen
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Secrets:**
   Since sensitive keys are omitted from version control for security, you must provide your own credentials.
   
   - **Firebase:** Download your `google-services.json` from the Firebase Console and place it in the `android/app/` directory.
   - **OpenWeather API:** Create a file at `lib/core/constants/secrets.dart` and add your API key:
     ```dart
     class Secrets {
       static const String weatherApiKey = 'YOUR_API_KEY_HERE';
     }
     ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📄 License
This project is part of a final academic thesis (Tugas Akhir) and is not licensed for commercial use without permission.
