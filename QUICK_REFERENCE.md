# QUICK REFERENCE & VISUAL GUIDE

## 📍 QUICK REFERENCE

### File-File Penting & Lokasi

| Fungsi | File Path | Deskripsi |
|--------|-----------|-----------|
| **Main Entry** | `lib/main.dart` | Initialization app, Firebase setup, Providers |
| **Navigation** | `lib/screen/navbar.dart` | Bottom navigation antar screen |
| **Auth** | `lib/auth/login_page.dart` | Login screen untuk semua platform |
| **Color System** | `lib/core/constants/app_colors.dart` | Semua warna aplikasi terpusat |
| **Language** | `lib/core/services/language_provider.dart` | Multi-language (ID, EN, JP, ES) |
| **Theme** | `lib/core/services/theme_provider.dart` | Dark/Light mode |
| **Errors** | `lib/core/errors/` | Exception & Failure handling |
| **Notification** | `lib/features/notification/notification_service.dart` | Local notifications |
| **Setup Wizard** | `lib/setup/setup_page.dart` | First-time user onboarding |

---

## 🔄 DATA FLOW DIAGRAMS

### 1. User Login Flow

```
┌─────────────┐
│   User      │
│ Opens App   │
└──────┬──────┘
       │
       ▼
┌──────────────────────────┐
│  Check Firebase Auth     │
│  (authStateChanges)      │
└──────┬───────────────────┘
       │
       ├─── No User ──────▶ OnboardingScreen
       │
       └─── User Found ───▶ Check Setup Status
                          in Firebase Database
                          │
                          ├─ Setup Complete ─▶ Navbar (Main App)
                          │
                          └─ Setup Incomplete ─▶ SetupPage (Wizard)
```

### 2. BMI Calculation Flow

```
User Input (Height, Weight)
        │
        ▼
┌──────────────────────────┐
│  BmiProvider.setHeight() │  ◀─ Update UI
│  BmiProvider.setWeight() │     (HumanPainter, GaugePainter)
└──────┬───────────────────┘
       │
       ▼ (User clicks "Next")
┌──────────────────────────┐
│ CalculateBmi UseCase     │
│ (Business Logic)         │
│ BMI = weight / height²   │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Determine Status & Color │
│ - Underweight (< 18.5)   │
│ - Normal (18.5-24.9)     │
│ - Overweight (25-29.9)   │
│ - Obesity (> 30)         │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ SaveBmiHistory UseCase   │
│ Save to Firebase         │
└──────┬───────────────────┘
       │
       ▼
Show Result Page with visualization
```

### 3. Workout Tracking Flow (GPS Sport)

```
┌──────────────────────────┐
│ User Selects Sport       │
│ (e.g., Running)          │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Request GPS Permission   │
│ Start Location Stream    │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ User Clicks "START"      │
│ Initialize:              │
│ - Timer (elapsed time)   │
│ - GPS points collection  │
│ - Calorie calculator     │
└──────┬───────────────────┘
       │
       ├─ Tracking Active ─────────────────────────┐
       │   (Real-time updates every 10m)          │
       │   - Update lat/lng coordinates           │
       │   - Calculate distance (Haversine)       │
       │   - Calculate calories (MET formula)     │
       │   - Update elapsed time                  │
       │                                          │
       ▼                                          │
   ┌─────────────────────────────────────────────┘
   │ User Clicks "STOP"
   │
   ▼
┌──────────────────────────┐
│ Create WorkoutEntity     │
│ - Duration               │
│ - Distance               │
│ - Calories               │
│ - GPS Route (polyline)   │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Save to Firebase:        │
│ users/{uid}/             │
│   workout_history/{id}   │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Add EXP (Experience)     │
│ Check Badges Earned      │
│ Update Statistics        │
└──────────────────────────┘
```

### 4. State Management Flow (Provider)

```
┌─────────────────────────┐
│    MyProvider           │ (Extends ChangeNotifier)
│ (State Container)       │
├─────────────────────────┤
│ state: value            │
│ update() {              │
│   value = newValue      │
│   notifyListeners()     │ ◀── Trigger rebuild
│ }                       │
└────────┬────────────────┘
         │
         ├──▶ Consumer<MyProvider>(
         │    builder: (ctx, provider, _) {
         │      Text(provider.value)
         │    }
         │   )
         │
         └──▶ MyWidget().watch<MyProvider>()
```

### 5. Clean Architecture Layers

```
┌──────────────────────────────────────────┐
│        PRESENTATION LAYER                │
│  (UI, Pages, Providers, Widgets)         │
│  🖥️ User sees & interacts here           │
└────────────────┬─────────────────────────┘
                 │ Depends on
                 ▼
┌──────────────────────────────────────────┐
│       DOMAIN LAYER                       │
│  (Business Logic, Entities, UseCases)    │
│  🧠 Pure business rules (no UI/DB code)  │
└────────────────┬─────────────────────────┘
                 │ Depends on
                 ▼
┌──────────────────────────────────────────┐
│        DATA LAYER                        │
│  (Repositories, DataSources, Models)     │
│  💾 Fetches/stores data (API, Firebase)  │
└──────────────────────────────────────────┘

Key Point:
- Domain ≠ Presentation ≠ Data
- Each can change independently
- No circular dependencies
```

---

## 🎯 COMMON TASKS

### 1. Add New Feature (e.g., "Meal Planner")

```
Step 1: Create Folder Structure
lib/features/meal_planner/
├── data/
│   ├── datasources/
│   │   └── meal_remote_datasource.dart
│   ├── repositories/
│   │   └── meal_repository_impl.dart
│   └── models/
│       └── meal_model.dart
├── domain/
│   ├── entities/
│   │   └── meal_entity.dart
│   ├── repositories/
│   │   └── meal_repository.dart
│   └── usecases/
│       ├── get_meal_plan.dart
│       └── save_meal.dart
└── presentation/
    ├── pages/
    │   └── meal_planner_page.dart
    ├── providers/
    │   └── meal_planner_provider.dart
    └── widgets/
        └── meal_card.dart

Step 2: Create Domain Layer
- meal_entity.dart: Pure object (no imports from data/presentation)
- meal_repository.dart: Interface (abstraction)
- get_meal_plan.dart: UseCase (business logic)

Step 3: Create Data Layer
- meal_remote_datasource.dart: Fetch dari API/Firebase
- meal_model.dart: Model dengan fromJson, toJson
- meal_repository_impl.dart: Implement interface dari domain

Step 4: Create Presentation Layer
- meal_planner_provider.dart: State management (ChangeNotifier)
- meal_planner_page.dart: UI screen
- meal_card.dart: Reusable component

Step 5: Add to main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => MealPlannerProvider(
        getMealPlan: GetMealPlan(mealRepo),
        saveMeal: SaveMeal(mealRepo),
      ),
    ),
  ],
)

Step 6: Add navigation di navbar.dart
Tambah tab/button untuk meal_planner_page
```

### 2. Fetch Data dari Firebase

```dart
// Example: Get user profile
Future<void> loadUserProfile() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    final snapshot = await FirebaseDatabase.instance
      .ref('users/$uid')
      .get();
    
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      
      // Convert ke entity
      final user = UserProfileEntity(
        uid: uid!,
        fullName: data['fullName'] ?? '',
        email: data['email'] ?? '',
        age: data['age'] ?? 0,
        gender: data['gender'] ?? 'Not Set',
      );
      
      userProfile = user;
      notifyListeners();
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}
```

### 3. Listen to Real-time Changes

```dart
// Example: Watch user's experience points
void startExpListener() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  
  _expSubscription = FirebaseDatabase.instance
    .ref('users/$uid/exp')
    .onValue
    .listen((event) {
      if (event.snapshot.exists) {
        currentExp = event.snapshot.value as int;
        currentRank = RankSystem.getRankByExp(currentExp);
        notifyListeners();
      }
    });
}

@override
void dispose() {
  _expSubscription?.cancel();
  super.dispose();
}
```

### 4. Display Loading State

```dart
// Pattern: Check isLoading flag
Consumer<MyProvider>(
  builder: (context, provider, _) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return ListView(
      children: [
        // Display data
      ],
    );
  },
)
```

### 5. Handle Error Messages

```dart
// Pattern: Use Either type for error handling
Future<void> myFunction() async {
  final result = await repository.getData();
  
  result.fold(
    (failure) {
      // Error case
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${failure.message}')),
      );
    },
    (data) {
      // Success case
      // Update state
      notifyListeners();
    },
  );
}
```

---

## 🛠️ DEBUGGING TIPS

### 1. Print Logs
```dart
debugPrint('🐛 Debug: $variable');
debugPrint('✅ Success: Data loaded');
debugPrint('❌ Error: ${error.message}');
```

### 2. Check Firebase Database
```
1. Go to https://console.firebase.google.com
2. Select your project
3. Go to Realtime Database
4. Browse structure real-time
5. Check if data is being saved correctly
```

### 3. Monitor Network Requests
```dart
// Add logging interceptor
final httpClient = http.Client();
httpClient.send(request).then((response) {
  debugPrint('Status: ${response.statusCode}');
  debugPrint('Body: ${response.body}');
});
```

### 4. Use Flutter DevTools
```bash
# Start DevTools
flutter pub global activate devtools
flutter devtools

# Then open browser at http://localhost:9100
# Use for:
# - Widget inspection
# - Memory profiling
# - Network monitoring
```

### 5. Test on Different Devices/Themes
```bash
# Run on device
flutter run

# Run in landscape
flutter run -d chrome --web-port 7357

# Test dark mode
# Open app → Settings → Toggle Dark Mode
```

---

## 📊 STATE MANAGEMENT PATTERNS

### Pattern 1: Simple Data Fetch

```dart
class MyProvider extends ChangeNotifier {
  List<Item> items = [];
  bool isLoading = false;
  
  Future<void> fetchItems() async {
    isLoading = true;
    notifyListeners();
    
    try {
      items = await repository.getItems();
    } catch (e) {
      debugPrint('Error: $e');
    }
    
    isLoading = false;
    notifyListeners();
  }
}
```

### Pattern 2: Form Handling

```dart
class FormProvider extends ChangeNotifier {
  String name = '';
  String email = '';
  Map<String, String> errors = {};
  
  void setName(String value) {
    name = value;
    notifyListeners();
  }
  
  bool validate() {
    errors.clear();
    
    if (name.isEmpty) {
      errors['name'] = 'Name required';
    }
    if (!email.contains('@')) {
      errors['email'] = 'Invalid email';
    }
    
    notifyListeners();
    return errors.isEmpty;
  }
  
  Future<void> submit() async {
    if (!validate()) return;
    
    await repository.saveForm(name, email);
    notifyListeners();
  }
}
```

### Pattern 3: Pagination

```dart
class ListProvider extends ChangeNotifier {
  List<Item> items = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  
  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;
    
    isLoading = true;
    notifyListeners();
    
    final newItems = await repository.getItems(page: currentPage);
    
    if (newItems.isEmpty) {
      hasMore = false;
    } else {
      items.addAll(newItems);
      currentPage++;
    }
    
    isLoading = false;
    notifyListeners();
  }
}
```

---

## 🎨 UI PATTERNS

### Pattern 1: Responsive Layout

```dart
// Use AppSize untuk responsive design
AppSize.init(context);

Container(
  width: AppSize.screenWidth * 0.8,  // 80% of screen
  height: AppSize.blockSizeVertical * 25, // 25% of height
  child: // ...
)
```

### Pattern 2: Loading State

```dart
// Generic loading wrapper
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  
  const LoadingOverlay({
    required this.isLoading,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
```

### Pattern 3: Empty State

```dart
// Show when no data
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
```

---

## 🔐 SECURITY BEST PRACTICES

### 1. API Keys
```dart
// ❌ JANGAN: Hardcode API key
const apiKey = 'your-key-here';

// ✅ DO: Use environment variable atau secrets file
// lib/core/constants/secrets.dart (add to .gitignore)
class Secrets {
  static const String weatherApiKey = 'your-key-here';
}
```

### 2. Firebase Security Rules
```
// Hanya user sendiri bisa akses profile mereka
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

### 3. Input Validation
```dart
// Always validate user input
bool validateEmail(String email) {
  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  return regex.hasMatch(email);
}

bool validatePassword(String password) {
  return password.length >= 8; // Minimum 8 char
}
```

---

## 📱 RESPONSIVE DESIGN CHECKLIST

- [ ] Test on phone (360x640)
- [ ] Test on tablet (600+)
- [ ] Test portrait & landscape
- [ ] Test dark mode
- [ ] Test with 200% text scale
- [ ] Test with slow network
- [ ] Test without internet
- [ ] Test with permission denied

---

## 🚀 OPTIMIZATION TIPS

### 1. Avoid Rebuilds
```dart
// ❌ Bad: Rebuilds entire tree
Provider.of<MyProvider>(context).name

// ✅ Good: Only rebuilds when name changes
Provider.of<MyProvider>(context, listen: false).name
// or
context.read<MyProvider>().name
```

### 2. Use Const Widgets
```dart
// ✅ Good: Won't rebuild
const Text('Hello'),
const SizedBox(height: 16),

// ❌ Bad: Rebuilds every time
Text('Hello'),
SizedBox(height: 16),
```

### 3. Use RepaintBoundary for Expensive Widgets
```dart
// For complex custom painters
RepaintBoundary(
  child: HumanPainter(height: height),
)
```

### 4. Lazy Load Images
```dart
Image.network(
  url,
  cacheHeight: 300,
  cacheWidth: 300,
  fit: BoxFit.cover,
)
```

---

## 📋 TESTING CHECKLIST

- [ ] Login dengan semua method (Google, Facebook, Email)
- [ ] Setup wizard lengkap
- [ ] BMI calculation akurat
- [ ] Workout tracking (indoor & outdoor)
- [ ] GPS tracking akurat
- [ ] Notification on time
- [ ] History history displaying correctly
- [ ] Badge unlocking
- [ ] Dark/Light mode toggle
- [ ] Language switching
- [ ] Offline capability (partial)
- [ ] No memory leaks
- [ ] No ANR (Application Not Responding)

---

**Quick Reference End**

*Keep this file handy for quick lookups!*
