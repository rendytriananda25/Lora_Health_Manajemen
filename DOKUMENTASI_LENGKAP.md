# 📚 DOKUMENTASI LENGKAP - LORA HEALTH MANAGEMENT APP

**Tanggal Pembuatan:** 2026  
**Bahasa:** Dart + Flutter  
**Arsitektur:** Clean Architecture (Domain-Driven Design)  
**Platform:** Mobile (Android & iOS)

---

## 📖 TABLE OF CONTENTS

1. [Overview Aplikasi](#overview)
2. [Struktur Folder & Arsitektur](#struktur-folder)
3. [Setup & Konfigurasi](#setup-konfigurasi)
4. [Dependencies & Libraries](#dependencies)
5. [Core Components](#core-components)
6. [Feature-by-Feature Explanation](#features)
7. [Database & Firebase](#database)
8. [Authentication Flow](#authentication)
9. [State Management](#state-management)
10. [Utility & Helper Functions](#utilities)

---

## <a name="overview"></a>📱 1. OVERVIEW APLIKASI

### Apa Itu LORA?

**LORA** adalah aplikasi mobile kesehatan dan fitness yang dirancang untuk membantu pengguna:
- Melacak kesehatan mereka dengan BMI Calculator
- Melakukan workout dengan panduan smart routine
- Melacak aktivitas outdoor menggunakan GPS
- Mengelola nutrisi harian
- Mendapatkan badge & achievement (gamification)
- Mendapatkan rekomendasi workout berdasarkan cuaca

### Target Pengguna
- Orang yang ingin memulai gaya hidup sehat
- Fitness enthusiast yang ingin tracking terstruktur
- User yang suka gamification & achievement

### Fitur-Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| **Dashboard** | Menampilkan info cuaca, rekomendasi workout, rank user, dan daily login bonus |
| **BMI Calculator** | Menghitung BMI dengan visualisasi dan history tracking |
| **Workout Tracking** | Workout indoor (home, basketball) dan outdoor (running, cycling) dengan GPS |
| **Nutrition Management** | Tracking kalori dan food recommendations |
| **History** | Melihat semua history workout, BMI, dan achievement |
| **Gamification** | Badge system dan rank/level untuk motivasi |
| **Settings** | User profile, language, notification, security |
| **Statistics** | Chart dan analytics workout & progress |

---

## <a name="struktur-folder"></a>🏗️ 2. STRUKTUR FOLDER & ARSITEKTUR

### Struktur Folder Umum

```
lora_1/
├── lib/
│   ├── main.dart                          # Entry point aplikasi
│   ├── firebase_options.dart              # Firebase configuration
│   ├── core/                              # Core utilities & constants
│   │   ├── constants/
│   │   │   ├── app_colors.dart           # Color palette aplikasi
│   │   │   └── app_constants.dart        # Static constants
│   │   ├── services/
│   │   │   ├── language_provider.dart    # Multi-language support
│   │   │   ├── theme_provider.dart       # Dark/Light mode
│   │   │   └── translation_service.dart  # Translation engine
│   │   ├── errors/
│   │   │   ├── exceptions.dart           # Custom exceptions
│   │   │   ├── failures.dart             # Error handling
│   │   │   └── either.dart               # Either type for Result handling
│   │   └── usecases/
│   │       └── usecase.dart              # Base usecase class
│   │
│   ├── features/                          # Main features
│   │   ├── dashboard/
│   │   ├── bmi/
│   │   ├── workout/
│   │   ├── history/
│   │   ├── statistics/
│   │   ├── settings/
│   │   ├── gamification/
│   │   ├── notification/
│   │   └── map/
│   │
│   ├── screen/                            # Screen/Navigation
│   ├── setup/                             # Setup wizard
│   ├── auth/                              # Authentication
│   └── providers/                         # Global providers
│
├── android/                                # Native Android code
├── ios/                                    # Native iOS code
├── assets/                                 # Images, sounds, translations
└── pubspec.yaml                           # Dependencies
```

### Clean Architecture Pattern

Setiap **Feature** mengikuti struktur Clean Architecture ini:

```
feature_name/
├── data/                    # Data Layer (Closest to external sources)
│   ├── datasources/        # API/Database calls
│   │   ├── *_remote_datasource.dart
│   │   └── *_local_datasource.dart
│   ├── repositories/       # Repository implementation
│   │   └── *_repository_impl.dart
│   └── models/             # Data models (serialization)
│
├── domain/                  # Domain Layer (Business Logic - Independent)
│   ├── entities/           # Pure business objects
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Business logic (seperti functions)
│
└── presentation/           # Presentation Layer (UI - Closest to user)
    ├── pages/              # Screen widgets
    ├── providers/          # State management (Provider)
    └── widgets/            # Reusable UI components
```

### Mengapa Clean Architecture?

**Keuntungan:**
- ✅ Mudah di-test (Business logic terpisah dari UI)
- ✅ Reusable (Bisa pakai logic di berbagai tempat)
- ✅ Scalable (Mudah tambah fitur baru)
- ✅ Maintainable (Kode terorganisir dengan jelas)
- ✅ Independent (UI bisa berubah, logic tetap sama)

---

## <a name="setup-konfigurasi"></a>⚙️ 3. SETUP & KONFIGURASI

### Prerequisites
- Flutter SDK (^3.8.1)
- Dart SDK
- Firebase Account
- Android Studio / VS Code

### Langkah-Langkah Setup

#### 1. **Inisialisasi Flutter & Dependencies**
```bash
# Clone atau buka project
cd lora_1

# Dapatkan semua dependencies
flutter pub get

# Upgrade Flutter
flutter upgrade
```

#### 2. **Konfigurasi Firebase**
```
1. Buka https://console.firebase.google.com
2. Buat project baru atau gunakan yang sudah ada
3. Download google-services.json untuk Android
4. Letakkan di: android/app/google-services.json
5. Download GoogleService-Info.plist untuk iOS
6. Letakkan di: ios/Runner/GoogleService-Info.plist
```

#### 3. **Konfigurasi API Keys**
Buat file `lib/core/constants/secrets.dart`:
```dart
class Secrets {
  static const String weatherApiKey = 'YOUR_OPENWEATHER_API_KEY';
  static const String openWeatherUrl = 'https://api.openweathermap.org/data/2.5';
}
```

#### 4. **Firebase Real-Time Database Structure**
Aplikasi ini menggunakan Firebase Real-Time Database dengan struktur:
```
users/
├── {user_id}/
│   ├── fullName
│   ├── email
│   ├── photoUrl
│   ├── age
│   ├── gender
│   ├── favorite_sports []
│   ├── bmi_history []
│   ├── workout_history []
│   ├── badges []
│   ├── exp
│   ├── level
│   └── daily_login_timestamp

nutrition/
├── items/
│   ├── {food_id}
│   │   ├── name
│   │   ├── calories
│   │   ├── protein
│   │   └── ...

workouts/
├── templates/
│   ├── home_workout
│   ├── basketball
│   └── ...
```

#### 5. **Run Aplikasi**
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

---

## <a name="dependencies"></a>📦 4. DEPENDENCIES & LIBRARIES

### Main Dependencies

```yaml
# Flutter & Framework
flutter: sdk

# State Management
provider: ^6.1.5+1          # Untuk ChangeNotifier & Consumer

# Firebase
firebase_core: ^4.4.0       # Firebase initialization
firebase_auth: ^6.1.4       # Authentication
firebase_database: ^12.1.2  # Real-time database
cloud_firestore: ^6.1.2     # Cloud Firestore (optional)

# Location & Map
geolocator: ^10.1.0         # GPS tracking
flutter_map: ^6.1.0         # Map display
latlong2: ^0.9.0            # Latitude/Longitude

# Authentication
google_sign_in: ^6.2.2      # Google auth
flutter_facebook_auth: ^7.0.0  # Facebook auth

# UI & UX
cupertino_icons: ^1.0.8     # iOS icons
smooth_page_indicator: ^2.0.1  # Page indicator

# Local Storage
shared_preferences: ^2.2.2  # Key-value storage
file_picker: ^8.1.2         # File selection

# Background & Notifications
flutter_background: ^1.3.0+1
flutter_local_notifications: ^17.2.2
alarm: ^4.1.1               # Alarm notifications

# Audio
audioplayers: ^5.2.1        # Sound playing

# QR Code
mobile_scanner: ^7.1.4      # QR code scanning

# HTTP
http: ^1.1.0                # API calls

# Utilities
intl: ^0.19.0               # Internationalization
timezone: ^0.9.4            # Timezone handling
url_launcher: ^6.3.2        # Open URLs
youtube_player_flutter: ^9.1.3  # YouTube integration
permission_handler: ^12.0.1  # Permission handling

# Monitoring
firebase_performance: ^0.11.4  # Performance monitoring
```

### Mengapa Library-Library Ini?

| Library | Alasan Penggunaan |
|---------|------------------|
| Provider | State management yang simple tapi powerful |
| Firebase | Backend-as-a-Service untuk auth & database |
| Geolocator | Real-time GPS tracking untuk workout |
| Flutter Map | Display map untuk visualisasi route |
| Audioplayers | Sound effects (tick sound saat BMI) |
| Local Notifications | Reminder workout & daily notification |
| Alarm | Background alarm untuk reminder |

---

## <a name="core-components"></a>🔧 5. CORE COMPONENTS

### A. `main.dart` - Entry Point Aplikasi

**File:** `lib/main.dart`

**Fungsi:** Initialization dan setup aplikasi sebelum run.

**Penjelasan Kode:**

```dart
void main() async {
  // 1. Initialize Flutter engine
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Load language preferences
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();
  
  // 3. Load theme preferences
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();
  
  // 4. Setup UI style (status bar, navigation bar)
  SystemChrome.setSystemUIOverlayStyle(...);
  SystemChrome.setPreferredOrientations(...);
  
  // 5. Initialize Firebase
  await Firebase.initializeApp(...);
  
  // 6. Initialize notifications
  await NotificationService.instance.init();
  await WorkoutReminderService.instance.initDefault();
  
  // 7. Load data dari Firebase
  NutritionData.fetchFromFirebase();
  WorkoutData.fetchFromFirebase();
  
  // 8. Setup Dependency Injection (repositories)
  final dashboardRepo = DashboardRepositoryImpl(...);
  final bmiRepo = BmiRepositoryImpl(...);
  // ... dsb
  
  // 9. Run app with MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        // ... providers untuk setiap feature
      ],
      child: const MyApp(),
    ),
  );
}
```

**Key Points:**
- Semua initialization dilakukan di `main()` sebelum UI dirender
- `MultiProvider` menyediakan semua state management di root
- Dependencies (repositories) dibuat di `main()` dan di-inject ke providers

### B. `MyApp` - Root Widget

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Lora Assistant',
      theme: themeProvider.themeData,
      home: Builder(
        builder: (context) {
          return StreamBuilder<User?>(
            // Firebase Auth stream untuk check login status
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.hasData) {
                // User sudah login, check apakah sudah setup
                return FutureBuilder<DataSnapshot>(
                  future: FirebaseDatabase.instanceFor(...)
                    .ref("users/${user.uid}/favorite_sports")
                    .get(),
                  builder: (context, dbSnapshot) {
                    if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                      return const Navbar(); // Main app
                    }
                    return const SetupPage(); // First-time setup
                  },
                );
              }
              return const OnboardingScreen(); // Not logged in
            },
          );
        },
      ),
    );
  }
}
```

**Flow:**
1. Check apakah user sudah login (FirebaseAuth)
2. Jika belum login → Tampilkan `OnboardingScreen`
3. Jika sudah login tapi belum setup → Tampilkan `SetupPage`
4. Jika sudah complete setup → Tampilkan `Navbar` (main app)

### C. `AppColors` - Design System

**File:** `lib/core/constants/app_colors.dart`

```dart
class AppColors {
  // Primary Color
  static const Color primary = Color(0xFF008BFF);  // Blue
  
  // Dark Mode Colors
  static const Color darkBg = Colors.black;        // Background
  static const Color darkBox = Color(0xFF141416);  // Card background
  static const Color darkText = Colors.white;      // Text color
  
  // Light Mode Colors
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightBox = Colors.white;
  static const Color lightText = Colors.black;
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);  // Green
  static const Color warning = Color(0xFFFF9800);  // Orange
  static const Color error = Color(0xFFE53935);    // Red
}
```

**Penggunaan:**
```dart
Container(
  color: theme.isDarkMode ? AppColors.darkBg : AppColors.lightBg,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.primary),
  ),
)
```

### D. `LanguageProvider` - Multi-Language Support

**File:** `lib/core/services/language_provider.dart`

**Fungsi:** Mengelola bahasa aplikasi (EN, ID, JP, ES)

**Kode Kunci:**
```dart
class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'id'; // Default: Indonesian
  
  // Load dari SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'id';
    notifyListeners();
  }
  
  // Change language
  Future<void> changeLanguage(String langCode) async {
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    notifyListeners();
  }
  
  // Translate text
  String translate(String key) {
    return TranslationService.translate(key, _currentLanguage);
  }
}
```

**Penggunaan:**
```dart
final lang = Provider.of<LanguageProvider>(context);
Text(lang.translate('dashboard.welcome')) // "Selamat Datang"
```

### E. `ThemeProvider` - Dark/Light Mode

**File:** `lib/core/services/theme_provider.dart`

**Fungsi:** Toggle antara dark mode dan light mode

```dart
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  // Get theme data
  ThemeData get themeData {
    return _isDarkMode 
      ? ThemeData.dark()
      : ThemeData.light();
  }
  
  // Get colors berdasarkan mode
  Color get bgColor => _isDarkMode ? AppColors.darkBg : AppColors.lightBg;
  Color get textColor => _isDarkMode ? AppColors.darkText : AppColors.lightText;
  
  // Toggle theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await SharedPreferences.getInstance()
      .then((prefs) => prefs.setBool('isDarkMode', _isDarkMode));
    notifyListeners();
  }
}
```

### F. `Either<L, R>` - Error Handling

**File:** `lib/core/errors/either.dart`

**Fungsi:** Functional programming pattern untuk handling success/error

```dart
// Either<Left, Right> biasanya: Either<Failure, Success>
Either<Failure, User> result = await userRepository.getUser();

// Pattern matching
result.fold(
  (failure) => print("Error: ${failure.message}"),
  (user) => print("Success: ${user.name}"),
);
```

**Keuntungan:**
- Explicit error handling (tidak ada try-catch)
- Type-safe (tahu apa error, apa success)
- Functional approach

---

## <a name="features"></a>🎯 6. FEATURE-BY-FEATURE EXPLANATION

Setiap feature dalam aplikasi ini mengikuti Clean Architecture. Mari kita bahas satu per satu:

---

### FEATURE #1: DASHBOARD

**File:** `lib/features/dashboard/`

**Deskripsi:** Homepage aplikasi yang menampilkan info cuaca, rekomendasi workout, user rank, dan daily rewards.

#### A. Domain Layer

**Entity:** `dashboard/domain/entities/`

1. **`user_profile_entity.dart`** - Objek user yang pure (business logic)
```dart
class UserProfileEntity {
  final String uid;
  final String fullName;
  final String email;
  final int age;
  final String gender;
  final String photoUrl;
  
  // Copy method untuk immutability
  UserProfileEntity copyWith({
    String? fullName,
    int? age,
  }) => UserProfileEntity(
    uid: uid,
    fullName: fullName ?? this.fullName,
    age: age ?? this.age,
  );
}
```

2. **`weather_entity.dart`** - Info cuaca
```dart
class WeatherEntity {
  final String city;
  final String temperature;
  final String condition; // "Sunny", "Rainy", dll
  final String aqi;       // Air Quality Index
  final String? recommendation; // Workout recommendation
}
```

3. **`food_entity.dart`** - Info makanan/nutrisi
```dart
class FoodEntity {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
}
```

**UseCase:** `dashboard/domain/usecases/`

1. **`get_weather_data.dart`** - Get cuaca dari API
```dart
class GetWeatherData {
  final DashboardRepository repository;
  
  Future<Either<Failure, WeatherEntity>> call(WeatherParams params) {
    return repository.getWeather(langCode: params.langCode);
  }
}

class WeatherParams {
  final String langCode;
}
```

2. **`get_user_profile.dart`** - Get profile user
```dart
class GetUserProfile {
  final DashboardRepository repository;
  
  Future<Either<Failure, UserProfileEntity>> call() {
    return repository.getUserProfile();
  }
}
```

3. **`generate_recommendations.dart`** - Generate text recommendations
```dart
class GenerateRecommendations {
  List<String> call(UserProfileEntity user, WeatherEntity weather) {
    // AI-generated recommendations berdasarkan user & cuaca
    return ["Cuaca cerah, ayo lari!", "Cocok untuk olahraga outdoor"];
  }
}
```

#### B. Data Layer

**DataSource:** `dashboard/data/datasources/`

1. **`weather_remote_datasource.dart`** - Fetch cuaca dari API
```dart
class WeatherRemoteDataSource {
  Future<Map<String, dynamic>> getWeatherData(String langCode) async {
    final response = await http.get(
      Uri.parse('${Secrets.openWeatherUrl}/weather?...')
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ServerException();
    }
  }
}
```

2. **`user_remote_datasource.dart`** - Fetch user dari Firebase
```dart
class UserRemoteDataSource {
  Future<Map<String, dynamic>> getUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseDatabase.instance
      .ref('users/$uid')
      .get();
    
    if (snapshot.exists) {
      return snapshot.value as Map<String, dynamic>;
    } else {
      throw ServerException();
    }
  }
}
```

**Repository:** `dashboard/data/repositories/`

```dart
class DashboardRepositoryImpl implements DashboardRepository {
  final WeatherRemoteDataSource weatherDataSource;
  final UserRemoteDataSource userDataSource;
  
  // Implement abstract methods dari DashboardRepository interface
  @override
  Future<Either<Failure, WeatherEntity>> getWeather({
    required String langCode,
  }) async {
    try {
      final result = await weatherDataSource.getWeatherData(langCode);
      // Convert dari map ke entity
      return Right(WeatherModel.fromJson(result).toEntity());
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

#### C. Presentation Layer

**Provider:** `dashboard/presentation/providers/dashboard_provider.dart`

```dart
class DashboardProvider extends ChangeNotifier {
  final GetWeatherData _getWeatherData;
  final GetUserProfile _getUserProfile;
  
  // State variables
  WeatherEntity weather = WeatherEntity.empty();
  UserProfileEntity userProfile = UserProfileEntity.empty();
  bool isLoading = true;
  
  // Initialize data saat pertama kali load
  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    
    await loadUserProfile();
    await loadWeather();
    await loadNutritionData();
    await loadLatestBmi();
    
    isLoading = false;
    notifyListeners();
  }
  
  // Fetch user profile
  Future<void> loadUserProfile() async {
    final result = await _getUserProfile();
    result.fold(
      (failure) => debugPrint('Error: ${failure.message}'),
      (data) => userProfile = data,
    );
    notifyListeners();
  }
  
  // Fetch cuaca
  Future<void> loadWeather({String langCode = 'id'}) async {
    final result = await _getWeatherData(
      WeatherParams(langCode: langCode)
    );
    result.fold(
      (failure) => weather = WeatherEntity(city: 'Koneksi Gagal', ...),
      (data) => weather = data,
    );
    notifyListeners();
  }
  
  // Check daily login bonus
  Future<int> checkDailyLogin() async {
    final lastLogin = SharedPreferences.getInstance()
      .then((prefs) => prefs.getInt('lastLoginDate') ?? 0);
    
    if (!isSameDay(lastLogin)) {
      // Award daily bonus exp
      return await _repository.addExperience(100);
    }
    return 0;
  }
}
```

**Page:** `dashboard/presentation/pages/dashboard_page.dart`

```dart
class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Initialize provider data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(
        context, 
        listen: false,
      );
      provider.init().then((_) {
        if (mounted) _checkDailyLogin(provider);
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        if (dashboard.isLoading) {
          return const CircularProgressIndicator();
        }
        
        return Column(
          children: [
            // Weather card
            GlassCard(
              child: Text(
                'City: ${dashboard.weather.city}',
              ),
            ),
            
            // User rank & exp
            Container(
              child: Text(
                'Level: ${dashboard.currentRank.level}',
              ),
            ),
            
            // Nutrition carousel
            NutritionCarousel(
              foods: dashboard.dailyPlan,
            ),
          ],
        );
      },
    );
  }
}
```

---

### FEATURE #2: BMI CALCULATOR

**File:** `lib/features/bmi/`

**Deskripsi:** Kalkulasi BMI dengan visual representation dan history tracking

#### A. Domain Layer

**Entity:** `bmi/domain/entities/bmi_result_entity.dart`
```dart
class BmiResultEntity {
  final double score;          // BMI value (e.g., 23.5)
  final String status;         // "Normal", "Overweight", "Obesity"
  final int colorHex;          // Color untuk status (0xFF008BFF)
}
```

**UseCase:** `bmi/domain/usecases/`

1. **`calculate_bmi.dart`** - Calculate BMI based on height & weight
```dart
class CalculateBmi {
  BmiResultEntity call({
    required int weightKg,  // Weight in kg
    required int heightCm,  // Height in cm
  }) {
    // Formula: BMI = weight / (height * height)
    double heightInMeter = heightCm / 100;
    double score = weightKg / (heightInMeter * heightInMeter);
    
    // Determine status & color
    String status = "Normal";
    int colorHex = 0xFF008BFF;
    
    if (score < 18.5) {
      status = "Underweight";
      colorHex = 0xFF448AFF;
    } else if (score < 25) {
      status = "Normal";
      colorHex = 0xFF008BFF;
    } else if (score < 30) {
      status = "Overweight";
      colorHex = 0xFFFF9800;
    } else {
      status = "Obesity";
      colorHex = 0xFFFF5252;
    }
    
    return BmiResultEntity(
      score: score,
      status: status,
      colorHex: colorHex,
    );
  }
}
```

**Penjelasan Formula:**
- **BMI = Berat (kg) / (Tinggi (m))²**
- Contoh: 70kg / (1.75m)² = 22.86 (Normal)

**BMI Categories:**
- < 18.5 = Underweight (Berat badan kurang)
- 18.5 - 24.9 = Normal (Ideal)
- 25 - 29.9 = Overweight (Berat badan berlebih)
- ≥ 30 = Obesity (Gemuk)

2. **`save_bmi_history.dart`** - Save BMI result ke Firebase
```dart
class SaveBmiHistory {
  final BmiRepository repository;
  
  Future<void> call({
    required double score,
    required String status,
    required int weight,
    required int height,
  }) {
    return repository.saveBmiHistory(
      score: score,
      status: status,
      weight: weight,
      height: height,
      timestamp: DateTime.now(),
    );
  }
}
```

#### B. Data Layer

**DataSource:** `bmi/data/datasources/bmi_remote_datasource.dart`
```dart
class BmiRemoteDataSource {
  Future<void> saveBmiHistory(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseDatabase.instance
      .ref('users/$uid/bmi_history')
      .push()
      .set(data);
  }
  
  Future<List<Map<String, dynamic>>> getBmiHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseDatabase.instance
      .ref('users/$uid/bmi_history')
      .get();
    
    if (snapshot.exists) {
      return (snapshot.value as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
```

**Repository:** `bmi/data/repositories/bmi_repository_impl.dart`
```dart
class BmiRepositoryImpl implements BmiRepository {
  final BmiRemoteDataSource remoteDataSource;
  
  @override
  Future<Either<Failure, void>> saveBmiHistory({
    required double score,
    required String status,
    required int weight,
    required int height,
  }) async {
    try {
      await remoteDataSource.saveBmiHistory({
        'score': score,
        'status': status,
        'weight': weight,
        'height': height,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

#### C. Presentation Layer

**Provider:** `bmi/presentation/providers/bmi_provider.dart`

```dart
class BmiProvider extends ChangeNotifier {
  final CalculateBmi _calculateBmiUseCase;
  final SaveBmiHistory _saveBmiHistoryUseCase;
  
  // State variables
  final PageController pageController = PageController();
  int currentPage = 0;      // 0: Height, 1: Weight, 2: Result
  int height = 170;         // Default height
  int weight = 60;          // Default weight
  int age = 24;             // Default age
  
  double bmiResult = 0;
  String bmiStatus = "";
  Color statusColor = Colors.green;
  
  // Sound effect untuk tick
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Update height (called saat user scroll wheel picker)
  void setHeight(int val) {
    height = val;
    playPremiumTick(); // Sound effect
    notifyListeners();
  }
  
  // Update weight
  void setWeight(int val) {
    weight = val;
    playPremiumTick();
    notifyListeners();
  }
  
  // Calculate BMI using usecase
  void calculateBMI() {
    final result = _calculateBmiUseCase(
      weightKg: weight,
      heightCm: height,
    );
    
    bmiResult = result.score;
    bmiStatus = result.status;
    statusColor = Color(result.colorHex);
    
    notifyListeners();
    
    // Save ke Firebase
    _saveBmiHistoryUseCase(
      score: bmiResult,
      status: bmiStatus,
      weight: weight,
      height: height,
    );
  }
  
  // Navigate to next page
  void nextPage() {
    if (currentPage >= 2) return;
    
    HapticFeedback.mediumImpact();
    playPremiumTick();
    
    pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart,
    );
    
    // Calculate BMI when leaving weight page
    if (currentPage == 1) calculateBMI();
    
    currentPage++;
    notifyListeners();
  }
  
  // Play tick sound
  void playPremiumTick() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/click.wav'));
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }
}
```

**Page:** `bmi/presentation/pages/bmi_page.dart`

```dart
class BMIPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BmiProvider>(
      builder: (context, bmiProvider, child) {
        return Scaffold(
          body: PageView(
            controller: bmiProvider.pageController,
            physics: const NeverScrollableScrollPhysics(), // Manual navigation
            children: [
              // Page 0: Height Selection
              _buildHeightPage(context, bmiProvider),
              
              // Page 1: Weight Selection
              _buildWeightPage(context, bmiProvider),
              
              // Page 2: BMI Result
              _buildResultPage(context, bmiProvider),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHeightPage(BuildContext context, BmiProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Select Height: ${provider.height} cm'),
        
        // Wheel picker untuk height
        HumanPainter(height: provider.height),
        
        SliderTheme(
          data: SliderThemeData(...),
          child: Slider(
            value: provider.height.toDouble(),
            min: 100,
            max: 220,
            onChanged: (value) {
              provider.setHeight(value.toInt());
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildWeightPage(BuildContext context, BmiProvider provider) {
    return Column(
      children: [
        Text('Select Weight: ${provider.weight} kg'),
        GaugePainter(weight: provider.weight),
        Slider(
          value: provider.weight.toDouble(),
          min: 30,
          max: 150,
          onChanged: (value) {
            provider.setWeight(value.toInt());
          },
        ),
      ],
    );
  }
  
  Widget _buildResultPage(BuildContext context, BmiProvider provider) {
    return Column(
      children: [
        Text('Your BMI: ${provider.bmiResult.toStringAsFixed(2)}'),
        Text(
          provider.bmiStatus,
          style: TextStyle(color: provider.statusColor),
        ),
        ElevatedButton(
          onPressed: () => provider.nextPage(),
          child: const Text('Back'),
        ),
      ],
    );
  }
}
```

**Custom Widgets:**

1. **`HumanPainter`** - Draw human silhouette based on height
```dart
class HumanPainter extends CustomPainter {
  final int height;
  
  @override
  void paint(Canvas canvas, Size size) {
    // Normalize height untuk canvas (100-220 → 0-1)
    double normalized = (height - 100) / 120;
    
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;
    
    // Draw head
    canvas.drawCircle(Offset(size.width / 2, 50), 20, paint);
    
    // Draw body (height affects this)
    double bodyHeight = 50 + normalized * 100;
    canvas.drawLine(
      Offset(size.width / 2, 70),
      Offset(size.width / 2, 70 + bodyHeight),
      paint,
    );
    
    // Draw legs
    // ...
  }
}
```

2. **`GaugePainter`** - Circular gauge untuk weight
```dart
class GaugePainter extends CustomPainter {
  final int weight;
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw arc gauge
    // Color berubah dari green (normal) → red (overweight)
    final colors = [Colors.green, Colors.yellow, Colors.red];
    final normalizedWeight = (weight - 30) / 120; // 30-150kg → 0-1
    
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 200,
        height: 200,
      ),
      -pi, // Start angle
      pi * normalizedWeight, // Sweep angle based on weight
      true,
      Paint()..color = _getColorForWeight(weight),
    );
  }
}
```

---

### FEATURE #3: WORKOUT TRACKING

**File:** `lib/features/workout/`

**Deskripsi:** Tracking workout indoor (home, basketball) dan outdoor (running, cycling) dengan GPS

#### A. Domain Layer

**Entity:** `workout/domain/entities/`

```dart
class WorkoutEntity {
  final String id;
  final String type;           // "home_workout", "running", "basketball"
  final String sport;          // Sport name
  final int duration;          // Duration in minutes
  final double distance;       // Distance in km (0 for indoor)
  final int caloriesBurned;
  final List<LatLng> gpsRoute; // GPS coordinates
  final DateTime timestamp;
  final String difficulty;     // "Easy", "Medium", "Hard"
}
```

**UseCase:** `workout/domain/usecases/`

```dart
class GetWorkoutRoutine {
  final WorkoutRepository repository;
  
  Future<Either<Failure, WorkoutEntity>> call(String sport) {
    return repository.getWorkoutRoutine(sport);
  }
}

class TrackWorkout {
  final WorkoutRepository repository;
  
  Future<Either<Failure, void>> call(WorkoutEntity workout) {
    return repository.saveWorkout(workout);
  }
}
```

#### B. Data Layer

**DataSource:** `workout/data/datasources/`

```dart
class WorkoutRemoteDataSource {
  // Get predefined workout routine dari Firebase
  Future<Map<String, dynamic>> getWorkoutRoutine(String sport) async {
    final snapshot = await FirebaseDatabase.instance
      .ref('workouts/templates/$sport')
      .get();
    
    if (snapshot.exists) {
      return snapshot.value as Map<String, dynamic>;
    }
    throw ServerException();
  }
  
  // Save workout ke Firebase
  Future<void> saveWorkout(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseDatabase.instance
      .ref('users/$uid/workout_history')
      .push()
      .set(data);
  }
}
```

**Repository:** `workout/data/repositories/workout_repository_impl.dart`

```dart
class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutRemoteDataSource dataSource;
  
  @override
  Future<Either<Failure, WorkoutEntity>> getWorkoutRoutine(
    String sport,
  ) async {
    try {
      final result = await dataSource.getWorkoutRoutine(sport);
      return Right(WorkoutModel.fromJson(result).toEntity());
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

#### C. Presentation Layer

**Provider:** `workout/presentation/providers/workout_provider.dart`

```dart
class WorkoutProvider extends ChangeNotifier {
  final WorkoutRepository _repository;
  
  // State variables
  bool isTracking = false;        // Apakah sedang tracking
  bool isGpsSport = false;        // Apakah sport pakai GPS
  String currentSport = "home";   // Current selected sport
  
  int elapsedSeconds = 0;         // Workout duration
  double distanceKm = 0;          // Distance traveled (GPS sports)
  int caloriesBurned = 0;         // Estimated calories
  List<LatLng> gpsRoute = [];      // GPS coordinates
  
  Timer? _timer;                  // Timer untuk elapsed time
  StreamSubscription? _locationStream; // Location stream
  
  // Initialize workout
  Future<void> init() async {
    // Load user's favorite sports
    final routines = await _repository.getUserFavoriteSports();
    // ...
  }
  
  // Generate workout routine based on user profile
  Future<void> generateRoutine(LanguageProvider lang) async {
    final result = await _repository.getWorkoutRoutine(currentSport);
    result.fold(
      (failure) => debugPrint('Error: ${failure.message}'),
      (routine) {
        // Display routine exercises
        currentRoutine = routine;
        notifyListeners();
      },
    );
  }
  
  // Start tracking workout
  void startTracking() {
    isTracking = true;
    elapsedSeconds = 0;
    gpsRoute = [];
    
    // Start timer
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      elapsedSeconds++;
      notifyListeners();
    });
    
    // Start GPS tracking jika GPS sport
    if (isGpsSport) {
      _startGpsTracking();
    }
    
    notifyListeners();
  }
  
  // GPS tracking untuk outdoor sports
  Future<void> _startGpsTracking() async {
    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update setiap 10 meter
      ),
    ).listen((Position position) {
      final point = LatLng(position.latitude, position.longitude);
      gpsRoute.add(point);
      
      // Calculate distance
      if (gpsRoute.length > 1) {
        final lastPoint = gpsRoute[gpsRoute.length - 2];
        distanceKm += _calculateDistance(lastPoint, point);
      }
      
      // Estimate calories based on sport & distance
      caloriesBurned = _estimateCalories();
      
      notifyListeners();
    });
  }
  
  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadiusKm = 6371;
    
    double dLat = (point2.latitude - point1.latitude) * pi / 180;
    double dLng = (point2.longitude - point1.longitude) * pi / 180;
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1.latitude * pi / 180) *
            cos(point2.latitude * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }
  
  // Estimate calories burned
  int _estimateCalories() {
    // Formula: calories = distance * MET * weight / 1.609
    // MET varies by sport (running ~10, cycling ~8, home workout ~4)
    final met = _getSportMET(currentSport);
    const weight = 70; // Assume 70kg user
    
    return (distanceKm * met * weight / 1.609).toInt();
  }
  
  double _getSportMET(String sport) {
    switch (sport) {
      case 'running':
        return 10;
      case 'cycling':
        return 8;
      case 'basketball':
        return 7;
      default:
        return 4; // Home workout
    }
  }
  
  // Stop tracking
  Future<void> stopTracking() async {
    isTracking = false;
    _timer?.cancel();
    _locationStream?.cancel();
    
    // Save workout to Firebase
    final workout = WorkoutEntity(
      id: const Uuid().v4(),
      type: currentSport,
      duration: elapsedSeconds ~/ 60,
      distance: distanceKm,
      caloriesBurned: caloriesBurned,
      gpsRoute: gpsRoute,
      timestamp: DateTime.now(),
    );
    
    await _repository.saveWorkout(workout);
    notifyListeners();
  }
}
```

**Page:** `workout/presentation/pages/workout_page.dart`

```dart
class WorkoutPage extends StatefulWidget {
  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  late MapController _mapController;
  
  @override
  void initState() {
    super.initInit();
    _mapController = MapController();
    
    // Initialize workout provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workout = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      workout.init().then((_) {
        workout.generateRoutine(Provider.of<LanguageProvider>(
          context,
          listen: false,
        ));
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, workout, _) {
        return Scaffold(
          body: Stack(
            children: [
              // Map display
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  minZoom: 13,
                  maxZoom: 19,
                ),
                children: [
                  // Map tiles from OpenStreetMap
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  
                  // Draw GPS route
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: workout.gpsRoute,
                        color: Colors.blue,
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                ],
              ),
              
              // Control panel overlay
              Positioned(
                top: 20,
                left: 20,
                child: GlassControlPanel(
                  isTracking: workout.isTracking,
                  sport: workout.currentSport,
                ),
              ),
              
              // Timer & stats
              if (workout.isTracking)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: TimerBackground(
                    duration: workout.elapsedSeconds,
                    distance: workout.distanceKm,
                    calories: workout.caloriesBurned,
                  ),
                ),
              
              // Start/Stop buttons
              Positioned(
                bottom: 20,
                right: 20,
                child: Column(
                  children: [
                    if (!workout.isTracking)
                      FloatingActionButton(
                        onPressed: _onStartTracking,
                        child: const Icon(Icons.play_arrow),
                      )
                    else
                      FloatingActionButton(
                        onPressed: _onStopTracking,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.stop),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _onStartTracking() {
    final workout = Provider.of<WorkoutProvider>(context, listen: false);
    workout.startTracking();
  }
  
  Future<void> _onStopTracking() async {
    final workout = Provider.of<WorkoutProvider>(context, listen: false);
    await workout.stopTracking();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved!')),
      );
    }
  }
}
```

---

### FEATURE #4: GAMIFICATION (Badges & Rank System)

**File:** `lib/features/gamification/`

**Deskripsi:** Badge achievements dan rank/level system untuk motivasi user

#### A. Badge System

**File:** `gamification/badges.dart`

```dart
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int requiredValue;      // e.g., 10 workouts
  final String type;            // "workout_count", "distance", etc
  
  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.requiredValue,
    required this.type,
  });
}

// Predefined badges
class Badges {
  static final List<Badge> allBadges = [
    Badge(
      id: 'first_workout',
      name: 'First Step',
      description: 'Complete your first workout',
      iconPath: 'assets/badges/first_step.png',
      requiredValue: 1,
      type: 'workout_count',
    ),
    Badge(
      id: 'workout_warrior',
      name: 'Workout Warrior',
      description: 'Complete 50 workouts',
      iconPath: 'assets/badges/warrior.png',
      requiredValue: 50,
      type: 'workout_count',
    ),
    Badge(
      id: 'marathon',
      name: 'Marathon Runner',
      description: 'Run 100km',
      iconPath: 'assets/badges/marathon.png',
      requiredValue: 100,
      type: 'total_distance',
    ),
    // ... more badges
  ];
}
```

**Badge Service:** `gamification/badge_service.dart`

```dart
class BadgeService {
  // Check if user earned new badge
  static Future<List<Badge>> checkNewBadges(
    UserProfile user,
    WorkoutHistory newWorkout,
  ) async {
    List<Badge> earnedBadges = [];
    
    for (var badge in Badges.allBadges) {
      if (badge.type == 'workout_count') {
        if (user.totalWorkouts >= badge.requiredValue) {
          if (!user.badges.contains(badge.id)) {
            earnedBadges.add(badge);
          }
        }
      } else if (badge.type == 'total_distance') {
        if (user.totalDistance >= badge.requiredValue) {
          if (!user.badges.contains(badge.id)) {
            earnedBadges.add(badge);
          }
        }
      }
    }
    
    // Save new badges to Firebase
    if (earnedBadges.isNotEmpty) {
      await _saveBadges(user.uid, earnedBadges);
    }
    
    return earnedBadges;
  }
  
  static Future<void> _saveBadges(
    String uid,
    List<Badge> badges,
  ) async {
    for (var badge in badges) {
      await FirebaseDatabase.instance
        .ref('users/$uid/badges')
        .push()
        .set({
          'id': badge.id,
          'name': badge.name,
          'earned_at': DateTime.now().toIso8601String(),
        });
    }
  }
}
```

#### B. Rank System

**File:** `gamification/rank_system.dart`

```dart
class RankData {
  final int level;
  final String name;           // "Beginner", "Intermediate", "Advanced"
  final int minExp;            // Min exp to reach this level
  final int maxExp;            // Max exp for this level
  final Color color;
  final String icon;
  
  int getExpProgress(int currentExp) {
    // Calculate progress % within this level
    int levelExp = currentExp - minExp;
    int levelRange = maxExp - minExp;
    return ((levelExp / levelRange) * 100).toInt();
  }
}

class RankSystem {
  static final List<RankData> ranks = [
    RankData(
      level: 1,
      name: 'Beginner',
      minExp: 0,
      maxExp: 500,
      color: Colors.green,
      icon: 'assets/ranks/beginner.png',
    ),
    RankData(
      level: 2,
      name: 'Intermediate',
      minExp: 500,
      maxExp: 1500,
      color: Colors.blue,
      icon: 'assets/ranks/intermediate.png',
    ),
    RankData(
      level: 3,
      name: 'Advanced',
      minExp: 1500,
      maxExp: 3500,
      color: Colors.purple,
      icon: 'assets/ranks/advanced.png',
    ),
    RankData(
      level: 4,
      name: 'Elite',
      minExp: 3500,
      maxExp: 7000,
      color: Colors.orange,
      icon: 'assets/ranks/elite.png',
    ),
  ];
  
  // Get rank based on exp
  static RankData getRankByExp(int exp) {
    for (var rank in ranks) {
      if (exp >= rank.minExp && exp < rank.maxExp) {
        return rank;
      }
    }
    return ranks.last;
  }
  
  // Calculate exp reward
  static int getExpReward(String workoutType, int durationMinutes) {
    // Different workouts give different exp
    // Home workout: 2 exp/min
    // Running: 3 exp/min
    // Basketball: 2.5 exp/min
    
    double multiplier = 2.0;
    switch (workoutType) {
      case 'running':
        multiplier = 3.0;
        break;
      case 'basketball':
        multiplier = 2.5;
        break;
    }
    
    return (durationMinutes * multiplier).toInt();
  }
}
```

#### C. Gamification Provider

```dart
class GamificationProvider extends ChangeNotifier {
  int totalExp = 0;
  RankData currentRank = RankSystem.ranks[0];
  List<Badge> earnedBadges = [];
  
  // Add experience
  Future<void> addExperience(int exp) async {
    totalExp += exp;
    
    // Check if leveled up
    final newRank = RankSystem.getRankByExp(totalExp);
    if (newRank.level > currentRank.level) {
      currentRank = newRank;
      // Show level up animation
      _showLevelUpAnimation();
    }
    
    notifyListeners();
    
    // Save to Firebase
    await _saveExp();
  }
  
  Future<void> _saveExp() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseDatabase.instance
      .ref('users/$uid/exp')
      .set(totalExp);
  }
}
```

---

### FEATURE #5: HISTORY & STATISTICS

**File:** `lib/features/history/` dan `lib/features/statistics/`

**Deskripsi:** View history workout dan detailed statistics/charts

#### History Provider

```dart
class HistoryProvider extends ChangeNotifier {
  final GetHistoryStream _getHistoryStream;
  
  List<Map<String, dynamic>> workoutHistory = [];
  StreamSubscription? _historySubscription;
  
  // Stream workout history from Firebase
  void initHistoryListener() {
    _historySubscription = _getHistoryStream().listen(
      (history) {
        workoutHistory = history;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error: $e'),
    );
  }
  
  // Delete history item
  Future<void> deleteHistoryItem(String workoutId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseDatabase.instance
      .ref('users/$uid/workout_history/$workoutId')
      .remove();
  }
  
  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }
}
```

#### Statistics Page

```dart
class StatisticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, history, _) {
        // Calculate statistics
        final totalWorkouts = history.workoutHistory.length;
        final totalDistance = _calculateTotalDistance(history.workoutHistory);
        final totalCalories = _calculateTotalCalories(history.workoutHistory);
        
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Statistics cards
                StatisticsCard(
                  title: 'Total Workouts',
                  value: '$totalWorkouts',
                  icon: Icons.fitness_center,
                ),
                StatisticsCard(
                  title: 'Total Distance',
                  value: '${totalDistance.toStringAsFixed(2)} km',
                  icon: Icons.directions_run,
                ),
                
                // Charts
                LineChartWidget(
                  data: history.workoutHistory,
                ),
                BarChartWidget(
                  data: history.workoutHistory,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

### FEATURE #6: SETTINGS & PROFILE

**File:** `lib/features/settings/`

**Deskripsi:** User profile, language, notification, security settings

#### Settings Provider

```dart
class SettingsProvider extends ChangeNotifier {
  final GetUserProfile _getUserProfile;
  final UpdateUserName _updateUserName;
  final SaveLocalPhoto _saveLocalPhoto;
  final LogoutUser _logoutUser;
  
  UserProfileEntity? _profile;
  bool _isLoading = false;
  
  // Fetch user profile
  Future<void> fetchProfileData() async {
    _isLoading = true;
    notifyListeners();
    
    final result = await _getUserProfile();
    result.fold(
      (failure) => debugPrint("Error: ${failure.message}"),
      (data) => _profile = data,
    );
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Update profile name
  Future<void> updateName(String newName) async {
    if (newName.trim().isEmpty) return;
    
    final result = await _updateUserName(newName);
    result.fold(
      (failure) => debugPrint("Error: ${failure.message}"),
      (_) {
        if (_profile != null) {
          _profile = _profile!.copyWith(fullName: newName);
          notifyListeners();
        }
      },
    );
  }
  
  // Upload profile picture
  Future<void> pickAndSaveImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        
        final saveResult = await _saveLocalPhoto(path);
        saveResult.fold(
          (failure) => debugPrint("Error: ${failure.message}"),
          (_) {
            if (_profile != null) {
              _profile = _profile!.copyWith(localPhotoPath: path);
              notifyListeners();
            }
          },
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
  
  // Logout
  Future<void> logout() async {
    final result = await _logoutUser();
    result.fold(
      (failure) => debugPrint("Error: ${failure.message}"),
      (_) => FirebaseAuth.instance.signOut(),
    );
  }
}
```

---

## <a name="database"></a>🗄️ 7. DATABASE & FIREBASE

### Firebase Real-Time Database Structure

```
users/
  {user_id}/
    fullName: "John Doe"
    email: "john@example.com"
    age: 24
    gender: "male"
    photoUrl: "https://..."
    
    favorite_sports: ["home_workout", "running"]
    
    bmi_history/
      {bmi_id}/
        score: 23.5
        status: "Normal"
        weight: 70
        height: 175
        timestamp: "2026-05-21T10:30:00Z"
    
    workout_history/
      {workout_id}/
        type: "running"
        duration: 45
        distance: 8.5
        caloriesBurned: 450
        gpsRoute: [
          {lat: -6.1234, lng: 106.5678},
          {lat: -6.1235, lng: 106.5679},
          ...
        ]
        timestamp: "2026-05-21T10:30:00Z"
    
    badges: ["first_workout", "workout_warrior"]
    
    exp: 2500
    level: 3
    
    daily_login_timestamp: "2026-05-21"

nutrition/
  items/
    {food_id}/
      name: "Chicken Rice"
      calories: 450
      protein: 25
      carbs: 45
      fat: 10

workouts/
  templates/
    home_workout/
      name: "Home Workout Day 1"
      exercises: [...]
      difficulty: "easy"
      duration: 30
    
    running/
      name: "Beginner Running Plan"
      exercises: [...]
```

---

## <a name="authentication"></a>🔐 8. AUTHENTICATION FLOW

### Login Flow

1. **Onboarding Screen** → User lihat pilihan login (Google, Facebook, Email)
2. **Firebase Auth** → User login via provider
3. **Check Setup** → Cek apakah user sudah setup favorite_sports
4. **Redirect** → Ke SetupPage (jika belum) atau Navbar (jika sudah)

### Code:

```dart
// main.dart
return StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, authSnapshot) {
    if (authSnapshot.hasData && authSnapshot.data != null) {
      // User sudah login, check setup
      final user = authSnapshot.data!;
      return FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instanceFor(...)
          .ref("users/${user.uid}/favorite_sports")
          .get(),
        builder: (context, dbSnapshot) {
          if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
            // Setup complete → Main app
            return const Navbar();
          }
          // Setup incomplete → Setup wizard
          return const SetupPage();
        },
      );
    }
    // Not logged in → Onboarding
    return const OnboardingScreen();
  },
);
```

---

## <a name="state-management"></a>📊 9. STATE MANAGEMENT (Provider)

Aplikasi menggunakan **Provider** untuk state management. Berikut cara kerjanya:

### A. ChangeNotifier Pattern

```dart
// Define provider
class MyProvider extends ChangeNotifier {
  int _count = 0;
  
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners(); // Notify UI to rebuild
  }
}

// Provide at root
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MyProvider()),
  ],
  child: MyApp(),
)

// Consume in widget
// Option 1: Consumer
Consumer<MyProvider>(
  builder: (context, provider, _) {
    return Text(provider.count.toString());
  },
)

// Option 2: Provider.of
final provider = Provider.of<MyProvider>(context);
Text(provider.count.toString())

// Option 3: Watch in StatelessWidget
final count = context.watch<MyProvider>().count;
```

### B. State Management Best Practices

```dart
// ✅ DO: Notify listeners after state change
void updateData(String newValue) {
  data = newValue;
  notifyListeners(); // Important!
}

// ❌ DON'T: Notify every small operation
void process() {
  notifyListeners(); // Line 1
  // ... more code
  notifyListeners(); // Line 5
  // ... more code
  notifyListeners(); // Line 10
}

// ✅ DO: Batch updates
void processMultiple() {
  data1 = value1;
  data2 = value2;
  data3 = value3;
  notifyListeners(); // Notify once at the end
}
```

---

## <a name="utilities"></a>🛠️ 10. UTILITY & HELPER FUNCTIONS

### A. App Size Utilities

**File:** `lib/core/utils/app_size.dart`

```dart
class AppSize {
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  
  static void init(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
  }
}

// Usage
AppSize.init(context);
Container(
  width: AppSize.blockSizeHorizontal * 50, // 50% of screen width
  height: AppSize.blockSizeVertical * 25,  // 25% of screen height
)
```

### B. Notification Service

**File:** `lib/features/notification/notification_service.dart`

```dart
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  static NotificationService get instance => _instance;
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Initialize notifications
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    
    await _notificationsPlugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }
  
  // Show notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
    );
  }
  
  // Schedule notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(...),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
```

### C. Location Service

**File:** `lib/features/map/services/location_service.dart`

```dart
class LocationService {
  // Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await Geolocator.requestPermission();
    
    return status == LocationPermission.granted ||
        status == LocationPermission.whileInUse;
  }
  
  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }
  
  // Get location updates
  static Stream<Position> getLocationUpdates() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update setiap 10 meter
      ),
    );
  }
}
```

### D. Date/Time Helpers

```dart
// Check if same day
bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

// Format duration
String formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final minutes = duration.inMinutes;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

// Format date
String formatDate(DateTime date) {
  return DateFormat('dd MMMM yyyy').format(date);
}
```

---

## 📋 RINGKASAN SINGKAT

| Komponen | File | Fungsi |
|----------|------|--------|
| Entry Point | `main.dart` | Initialize app, setup Firebase, DI |
| Design System | `app_colors.dart` | Color palette konsisten |
| Localization | `language_provider.dart` | Multi-language support |
| Theme | `theme_provider.dart` | Dark/Light mode |
| State Mgmt | `*_provider.dart` | Business logic & state |
| Pages | `*_page.dart` | UI screens |
| Entities | `*_entity.dart` | Pure business objects |
| UseCase | `*_usecase.dart` | Business logic rules |
| Repository | `*_repository_impl.dart` | Data access abstraction |
| DataSource | `*_datasource.dart` | API/Database calls |
| Notifications | `notification_service.dart` | Local notifications |

---

## 🚀 TIPS DEVELOPMENT

### 1. Menambah Feature Baru
```
1. Buat folder: lib/features/my_feature/
2. Struktur: domain/, data/, presentation/
3. Domain dulu (entities, repositories interfaces)
4. Data layer (datasources, repository impl)
5. Presentation (providers, pages)
6. Add provider ke main.dart MultiProvider
```

### 2. Debugging
```dart
// Use debugPrint untuk see logs
debugPrint('🐛 Debug: $value');

// Use Flutter DevTools
flutter pub global activate devtools
flutter devtools
```

### 3. Testing
```dart
// Unit test for business logic
test('Calculate BMI', () {
  final bmi = CalculateBmi();
  final result = bmi(weightKg: 70, heightCm: 175);
  expect(result.score, closeTo(22.86, 0.01));
});
```

---

## 📞 TROUBLESHOOTING

| Masalah | Solusi |
|---------|--------|
| Firebase not initialized | Pastikan `firebase_options.dart` ada dan sesuai |
| Hot reload tidak update | Gunakan `flutter clean` lalu `flutter pub get` |
| GPS tidak berfungsi | Check permission di AndroidManifest.xml |
| Notification tidak muncul | Check notification channel di Android |
| Build error | Upgrade Flutter: `flutter upgrade` |

---

**End of Documentation**

*Last Updated: 2026-05-21*  
*For questions, check Firebase console dan code comments*
