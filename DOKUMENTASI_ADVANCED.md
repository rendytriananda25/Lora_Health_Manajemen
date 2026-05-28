# DOKUMENTASI DETAIL - ADVANCED FEATURES & IMPLEMENTATION

## DAFTAR ISI
1. [Authentication System Detail](#auth-detail)
2. [Notification & Reminder System](#notification-system)
3. [Setup Wizard Flow](#setup-wizard)
4. [Custom Widgets](#custom-widgets)
5. [Translation System](#translation-system)
6. [Background Services](#background-services)
7. [Error Handling](#error-handling)
8. [Database Query Examples](#database-queries)

---

## <a name="auth-detail"></a>🔐 AUTHENTICATION SYSTEM DETAIL

### Firebase Auth Integration

**File:** `lib/auth/services/auth_service.dart`

```dart
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  // Sign up with email & password
  Future<Either<Failure, UserCredential>> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      // Create user di Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save user profile ke Realtime Database
      final uid = userCredential.user!.uid;
      await _database.ref('users/$uid').set({
        'fullName': fullName,
        'email': email,
        'age': 0,
        'gender': 'Not Set',
        'photoUrl': '',
        'createdAt': DateTime.now().toIso8601String(),
        'exp': 0,
        'level': 1,
      });
      
      return Right(userCredential);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: e.message ?? 'Auth error'));
    }
  }
  
  // Google Sign In
  Future<Either<Failure, UserCredential>> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return Left(AuthFailure(message: 'Google sign-in cancelled'));
      }
      
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      // Save user profile
      final uid = userCredential.user!.uid;
      final userRef = _database.ref('users/$uid');
      
      final snapshot = await userRef.get();
      if (!snapshot.exists) {
        // First time user, create profile
        await userRef.set({
          'fullName': googleUser.displayName ?? '',
          'email': googleUser.email,
          'photoUrl': googleUser.photoUrl ?? '',
          'age': 0,
          'gender': 'Not Set',
          'createdAt': DateTime.now().toIso8601String(),
          'exp': 0,
          'level': 1,
        });
      }
      
      return Right(userCredential);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: e.message ?? 'Google auth failed'));
    }
  }
  
  // Facebook Sign In
  Future<Either<Failure, UserCredential>> signInWithFacebook() async {
    try {
      final facebookAuth = FacebookAuth.instance;
      final loginResult = await facebookAuth.login();
      
      if (loginResult.status == LoginStatus.cancelled) {
        return Left(AuthFailure(message: 'Facebook login cancelled'));
      }
      
      final credential = FacebookAuthProvider.credential(
        loginResult.accessToken!.tokenString,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      // Save user profile
      // ... (similar to Google)
      
      return Right(userCredential);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: e.message ?? 'Facebook auth failed'));
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
  }
  
  // Get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
  
  // Listen to auth state changes
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }
}
```

### Login Page Implementation

**File:** `lib/auth/login_page.dart`

```dart
class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Login dengan email & password
  Future<void> _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Email dan password harus diisi');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted && userCredential.user != null) {
        // Navigate to next screen
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Coba lagi nanti';
      default:
        return 'Terjadi kesalahan. Coba lagi';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),
              Text(
                'LORA',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              
              // Email input
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Password input
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              
              // Error message
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              
              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _loginWithEmail,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
              const SizedBox(height: 16),
              
              // Divider
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Atau'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              
              // Google sign in button
              ElevatedButton.icon(
                onPressed: _loginWithGoogle,
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Login dengan Google'),
              ),
              const SizedBox(height: 12),
              
              // Facebook sign in button
              ElevatedButton.icon(
                onPressed: _loginWithFacebook,
                icon: const Icon(Icons.facebook),
                label: const Text('Login dengan Facebook'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _loginWithGoogle() async {
    // Implementation similar to AuthService
  }
  
  Future<void> _loginWithFacebook() async {
    // Implementation similar to AuthService
  }
}
```

---

## <a name="notification-system"></a>🔔 NOTIFICATION & REMINDER SYSTEM

### Notification Service

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
  
  // Initialize notification plugin
  Future<void> init() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    // Initialize
    await _notificationsPlugin.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }
  
  // Handle when notification is tapped
  void _handleNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    final payload = notificationResponse.payload;
    if (payload != null) {
      // Navigate to relevant page based on payload
      debugPrint('Notification tapped: $payload');
    }
  }
  
  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'lora_channel',
      'LORA Notifications',
      channelDescription: 'Notifikasi dari LORA',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'LORA',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  // Schedule notification untuk waktu tertentu
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'lora_scheduled_channel',
      'LORA Scheduled Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
  
  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
```

### Workout Reminder Service

**File:** `lib/features/notification/workout_reminder_service.dart`

```dart
class WorkoutReminderService {
  static final WorkoutReminderService _instance =
      WorkoutReminderService._internal();
  
  factory WorkoutReminderService() {
    return _instance;
  }
  
  WorkoutReminderService._internal();
  
  static WorkoutReminderService get instance => _instance;
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Initialize with default reminders
  Future<void> initDefault() async {
    // Set default reminder times
    await scheduleReminder(
      title: 'Time to workout!',
      body: 'Your scheduled workout starts in 10 minutes',
      hour: 7,  // 7 AM
      minute: 0,
      id: 1,
    );
    
    await scheduleReminder(
      title: 'Evening workout',
      body: 'Time for your evening workout!',
      hour: 18, // 6 PM
      minute: 0,
      id: 2,
    );
  }
  
  // Schedule recurring reminder
  Future<void> scheduleReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int id,
  }) async {
    // Hitung waktu reminder berikutnya
    var now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    // Jika waktu sudah lewat hari ini, schedule untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // Schedule dengan weekly repeat
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Workout Reminders',
          importance: Importance.high,
          priority: Priority.high,
          // ... settings
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
    );
  }
}
```

---

## <a name="setup-wizard"></a>⚙️ SETUP WIZARD FLOW

**File:** `lib/setup/setup_page.dart`

```dart
class SetupPage extends StatefulWidget {
  const SetupPage({super.key});
  
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int currentStep = 0;
  List<String> selectedSports = [];
  int age = 25;
  String gender = 'male';
  String fitnessGoal = 'general';
  
  // Setup steps:
  // 0: Welcome
  // 1: Personal Info (age, gender)
  // 2: Fitness Goal
  // 3: Sport Selection
  // 4: Confirmation
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (currentStep > 0) {
          setState(() => currentStep--);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: PageView(
          controller: PageController(initialPage: currentStep),
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() => currentStep = index);
          },
          children: [
            // Step 0: Welcome
            _buildWelcomeStep(),
            
            // Step 1: Personal Info
            _buildPersonalInfoStep(),
            
            // Step 2: Fitness Goal
            _buildFitnessGoalStep(),
            
            // Step 3: Sport Selection
            _buildSportSelectionStep(),
            
            // Step 4: Confirmation
            _buildConfirmationStep(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Selamat Datang di LORA!',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 24),
        Text(
          'Mari kita setup profil kamu untuk pengalaman terbaik',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _nextStep,
          child: const Text('Mulai Setup'),
        ),
      ],
    );
  }
  
  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        Text('Berapa umur kamu?'),
        Slider(
          value: age.toDouble(),
          min: 10,
          max: 80,
          onChanged: (value) {
            setState(() => age = value.toInt());
          },
        ),
        Text('$age tahun'),
        const SizedBox(height: 32),
        Text('Jenis kelamin?'),
        Row(
          children: [
            Radio(
              value: 'male',
              groupValue: gender,
              onChanged: (value) {
                setState(() => gender = value!);
              },
            ),
            const Text('Laki-laki'),
            Radio(
              value: 'female',
              groupValue: gender,
              onChanged: (value) {
                setState(() => gender = value!);
              },
            ),
            const Text('Perempuan'),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            ElevatedButton(
              onPressed: _previousStep,
              child: const Text('Kembali'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _nextStep,
              child: const Text('Lanjut'),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFitnessGoalStep() {
    return Column(
      children: [
        Text('Tujuan fitness kamu?'),
        ..._buildGoalButtons(),
        const Spacer(),
        Row(
          children: [
            ElevatedButton(
              onPressed: _previousStep,
              child: const Text('Kembali'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _nextStep,
              child: const Text('Lanjut'),
            ),
          ],
        ),
      ],
    );
  }
  
  List<Widget> _buildGoalButtons() {
    final goals = [
      ('general', 'Kesehatan Umum'),
      ('weight_loss', 'Turun Berat Badan'),
      ('muscle_gain', 'Tambah Otot'),
      ('endurance', 'Stamina & Ketahanan'),
    ];
    
    return goals.map((goal) {
      return GestureDetector(
        onTap: () {
          setState(() => fitnessGoal = goal.$1);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: fitnessGoal == goal.$1 ? Colors.blue : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(goal.$2),
        ),
      );
    }).toList();
  }
  
  Widget _buildSportSelectionStep() {
    return Column(
      children: [
        Text('Pilih olahraga favorit kamu:'),
        ..._buildSportCheckboxes(),
        const Spacer(),
        Row(
          children: [
            ElevatedButton(
              onPressed: _previousStep,
              child: const Text('Kembali'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: selectedSports.isEmpty ? null : _nextStep,
              child: const Text('Lanjut'),
            ),
          ],
        ),
      ],
    );
  }
  
  List<Widget> _buildSportCheckboxes() {
    final sports = [
      'home_workout',
      'running',
      'cycling',
      'basketball',
    ];
    
    return sports.map((sport) {
      return CheckboxListTile(
        title: Text(sport),
        value: selectedSports.contains(sport),
        onChanged: (value) {
          setState(() {
            if (value == true) {
              selectedSports.add(sport);
            } else {
              selectedSports.remove(sport);
            }
          });
        },
      );
    }).toList();
  }
  
  Widget _buildConfirmationStep() {
    return Column(
      children: [
        Text('Konfirmasi Data:'),
        ListTile(title: const Text('Umur'), subtitle: Text('$age tahun')),
        ListTile(title: const Text('Gender'), subtitle: Text(gender)),
        ListTile(
          title: const Text('Tujuan'),
          subtitle: Text(fitnessGoal),
        ),
        ListTile(
          title: const Text('Olahraga'),
          subtitle: Text(selectedSports.join(', ')),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _saveSetup,
          child: const Text('Selesai Setup'),
        ),
      ],
    );
  }
  
  void _nextStep() {
    if (currentStep < 4) {
      setState(() => currentStep++);
    }
  }
  
  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }
  
  Future<void> _saveSetup() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    // Save setup data to Firebase
    await FirebaseDatabase.instance.ref('users/$uid').update({
      'age': age,
      'gender': gender,
      'fitness_goal': fitnessGoal,
      'favorite_sports': selectedSports,
      'setup_complete': true,
      'setup_date': DateTime.now().toIso8601String(),
    });
    
    if (mounted) {
      // Navigate to main app
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
```

---

## <a name="custom-widgets"></a>🎨 CUSTOM WIDGETS

### GlassCard - Glassmorphism Widget

**File:** `lib/features/bmi/widgets/glass_card.dart`

```dart
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsets padding;
  
  const GlassCard({
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.padding = const EdgeInsets.all(16),
  });
  
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          // Frosted glass effect
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

// Usage
GlassCard(
  child: Column(
    children: [
      Text('Weather Info'),
      Text('25°C - Sunny'),
    ],
  ),
)
```

### HumanPainter - Custom Painter untuk Visualisasi Tinggi Badan

**File:** `lib/features/bmi/widgets/human_painter.dart`

```dart
class HumanPainter extends CustomPainter {
  final int height;
  
  HumanPainter({required this.height});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // Normalisasi height (100-220 cm → 0-1)
    double normalized = (height - 100) / 120;
    if (normalized < 0) normalized = 0;
    if (normalized > 1) normalized = 1;
    
    final centerX = size.width / 2;
    final headRadius = 15.0;
    final bodyStartY = 50.0;
    final bodyHeight = normalized * 150; // Max 150 units
    
    // Draw head (lingkaran)
    canvas.drawCircle(
      Offset(centerX, headRadius + 10),
      headRadius,
      paint,
    );
    
    // Draw body (vertical line)
    canvas.drawLine(
      Offset(centerX, bodyStartY),
      Offset(centerX, bodyStartY + bodyHeight),
      paint,
    );
    
    // Draw left arm
    canvas.drawLine(
      Offset(centerX, bodyStartY + 20),
      Offset(centerX - 30, bodyStartY + 50),
      paint,
    );
    
    // Draw right arm
    canvas.drawLine(
      Offset(centerX, bodyStartY + 20),
      Offset(centerX + 30, bodyStartY + 50),
      paint,
    );
    
    // Draw left leg
    canvas.drawLine(
      Offset(centerX, bodyStartY + bodyHeight),
      Offset(centerX - 20, bodyStartY + bodyHeight + 50),
      paint,
    );
    
    // Draw right leg
    canvas.drawLine(
      Offset(centerX, bodyStartY + bodyHeight),
      Offset(centerX + 20, bodyStartY + bodyHeight + 50),
      paint,
    );
    
    // Draw height reference line (sebelah kiri)
    final refPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(20, bodyStartY),
      Offset(20, bodyStartY + bodyHeight),
      refPaint,
    );
    
    // Draw height text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${height.toStringAsFixed(0)} cm',
        style: const TextStyle(color: Colors.black, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, bodyStartY + bodyHeight + 70),
    );
  }
  
  @override
  bool shouldRepaint(HumanPainter oldDelegate) {
    return oldDelegate.height != height;
  }
}
```

### GaugePainter - Circular Gauge untuk Weight

**File:** `lib/features/bmi/widgets/gauge_painter.dart`

```dart
class GaugePainter extends CustomPainter {
  final int weight;
  final int minWeight;
  final int maxWeight;
  
  GaugePainter({
    required this.weight,
    this.minWeight = 30,
    this.maxWeight = 150,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(size.width, size.height) / 2 - 20;
    
    // Draw background arc (grey)
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: radius * 2,
        height: radius * 2,
      ),
      -pi,
      pi,
      false,
      backgroundPaint,
    );
    
    // Calculate progress
    double progress = (weight - minWeight) / (maxWeight - minWeight);
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;
    
    // Determine color based on weight (BMI indicator)
    // Calculate BMI assuming average height 170cm
    double bmi = weight / (1.7 * 1.7);
    Color arcColor;
    
    if (bmi < 18.5) {
      arcColor = Colors.blue; // Underweight
    } else if (bmi < 25) {
      arcColor = Colors.green; // Normal
    } else if (bmi < 30) {
      arcColor = Colors.orange; // Overweight
    } else {
      arcColor = Colors.red; // Obesity
    }
    
    // Draw progress arc
    final progressPaint = Paint()
      ..color = arcColor
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: radius * 2,
        height: radius * 2,
      ),
      -pi,
      pi * progress,
      false,
      progressPaint,
    );
    
    // Draw center circle (weight value)
    final centerPaint = Paint()
      ..color = arcColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(centerX, centerY), radius / 2, centerPaint);
    
    // Draw weight text
    final textPainter = TextPainter(
      text: TextSpan(
        text: weight.toString(),
        style: TextStyle(
          color: arcColor,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        centerY - textPainter.height / 2,
      ),
    );
    
    // Draw "kg" text below
    final kgPainter = TextPainter(
      text: const TextSpan(
        text: 'kg',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    
    kgPainter.layout();
    kgPainter.paint(
      canvas,
      Offset(
        centerX - kgPainter.width / 2,
        centerY + textPainter.height / 2 + 10,
      ),
    );
  }
  
  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.weight != weight;
  }
}
```

---

## <a name="translation-system"></a>🌍 TRANSLATION SYSTEM

### Translation Service

**File:** `lib/core/services/translation_service.dart`

```dart
class TranslationService {
  static final Map<String, Map<String, String>> _translations = {
    'id': {
      'dashboard.welcome': 'Selamat Datang',
      'dashboard.todaysPlan': 'Rencana Hari Ini',
      'bmi.selectHeight': 'Pilih Tinggi Badan',
      'bmi.selectWeight': 'Pilih Berat Badan',
      'bmi.result': 'Hasil BMI',
      'workout.start': 'Mulai Workout',
      'workout.stop': 'Berhenti',
      'common.loading': 'Memuat...',
      'common.error': 'Terjadi Kesalahan',
      'common.save': 'Simpan',
      'common.cancel': 'Batal',
    },
    'en': {
      'dashboard.welcome': 'Welcome',
      'dashboard.todaysPlan': "Today's Plan",
      'bmi.selectHeight': 'Select Height',
      'bmi.selectWeight': 'Select Weight',
      'bmi.result': 'BMI Result',
      'workout.start': 'Start Workout',
      'workout.stop': 'Stop',
      'common.loading': 'Loading...',
      'common.error': 'An Error Occurred',
      'common.save': 'Save',
      'common.cancel': 'Cancel',
    },
    'ja': {
      'dashboard.welcome': 'ようこそ',
      'dashboard.todaysPlan': '今日の計画',
      'bmi.selectHeight': '身長を選択',
      'bmi.selectWeight': '体重を選択',
      'bmi.result': 'BMI結果',
      'workout.start': 'ワークアウトを開始',
      'workout.stop': '停止',
      'common.loading': '読み込み中...',
      'common.error': 'エラーが発生しました',
      'common.save': '保存',
      'common.cancel': 'キャンセル',
    },
    'es': {
      'dashboard.welcome': 'Bienvenido',
      'dashboard.todaysPlan': 'Plan de Hoy',
      'bmi.selectHeight': 'Seleccionar Altura',
      'bmi.selectWeight': 'Seleccionar Peso',
      'bmi.result': 'Resultado del IMC',
      'workout.start': 'Comenzar Entrenamiento',
      'workout.stop': 'Detener',
      'common.loading': 'Cargando...',
      'common.error': 'Ocurrió un Error',
      'common.save': 'Guardar',
      'common.cancel': 'Cancelar',
    },
  };
  
  static String translate(String key, String languageCode) {
    return _translations[languageCode]?[key] ?? key;
  }
  
  static Map<String, String> getLanguageMap(String languageCode) {
    return _translations[languageCode] ?? _translations['en']!;
  }
  
  static List<String> getSupportedLanguages() {
    return _translations.keys.toList();
  }
}
```

### Language Provider

```dart
class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'id';
  
  String get currentLanguage => _currentLanguage;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'id';
    notifyListeners();
  }
  
  Future<void> changeLanguage(String langCode) async {
    if (!TranslationService.getSupportedLanguages().contains(langCode)) {
      return;
    }
    
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    
    notifyListeners();
  }
  
  String translate(String key) {
    return TranslationService.translate(key, _currentLanguage);
  }
  
  // Get all translations for current language
  Map<String, String> get translations {
    return TranslationService.getLanguageMap(_currentLanguage);
  }
}
```

---

## <a name="background-services"></a>🔄 BACKGROUND SERVICES

### Background Workout Tracking

**File:** `lib/features/map/services/session_completion_service.dart`

```dart
class SessionCompletionService {
  // Ensure workout completion even if app is killed
  static Future<void> ensureWorkoutSaved(
    WorkoutEntity workout,
  ) async {
    try {
      // Save to local storage first (as backup)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pending_workout_${workout.id}',
        jsonEncode(workout.toJson()),
      );
      
      // Try to save to Firebase
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseDatabase.instance
          .ref('users/$uid/workout_history/${workout.id}')
          .set(workout.toJson());
        
        // Remove from local storage after successful save
        await prefs.remove('pending_workout_${workout.id}');
      }
    } catch (e) {
      debugPrint('Error saving workout: $e');
      // Data is safe in SharedPreferences, will try again later
    }
  }
  
  // Sync pending workouts when app resumes
  static Future<void> syncPendingWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final pendingKeys = keys.where((k) => k.startsWith('pending_workout_'));
      
      for (String key in pendingKeys) {
        final workoutJson = prefs.getString(key);
        if (workoutJson != null) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            final workout = jsonDecode(workoutJson);
            await FirebaseDatabase.instance
              .ref('users/$uid/workout_history/${workout['id']}')
              .set(workout);
            
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing pending workouts: $e');
    }
  }
}
```

---

## <a name="error-handling"></a>⚠️ ERROR HANDLING

### Custom Exceptions & Failures

**File:** `lib/core/errors/exceptions.dart`

```dart
// Custom Exceptions
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);
}

class ServerException extends AppException {
  ServerException([String message = 'Server Error']) : super(message);
}

class CacheException extends AppException {
  CacheException([String message = 'Cache Error']) : super(message);
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network Error']) : super(message);
}

class LocationException extends AppException {
  LocationException([String message = 'Location Error']) : super(message);
}

class AuthException extends AppException {
  AuthException([String message = 'Auth Error']) : super(message);
}
```

**File:** `lib/core/errors/failures.dart`

```dart
abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure([String message = 'Server Error']) : super(message);
}

class CacheFailure extends Failure {
  CacheFailure([String message = 'Cache Error']) : super(message);
}

class NetworkFailure extends Failure {
  NetworkFailure([String message = 'Network Error']) : super(message);
}

class AuthFailure extends Failure {
  AuthFailure({required String message}) : super(message);
}

class LocationFailure extends Failure {
  LocationFailure([String message = 'Location Error']) : super(message);
}
```

### Error Handling Best Practice

```dart
// Pattern: Try-catch dengan Either return type
Future<Either<Failure, UserEntity>> getUser() async {
  try {
    // Try to fetch from Firebase
    final data = await firebaseDatabase
      .ref('users/${userId}')
      .get();
    
    if (data.exists) {
      return Right(UserModel.fromJson(data.value).toEntity());
    } else {
      return Left(ServerFailure('User not found'));
    }
  } on FirebaseException catch (e) {
    return Left(ServerFailure(e.message ?? 'Firebase Error'));
  } on SocketException {
    return Left(NetworkFailure('No internet connection'));
  } catch (e) {
    return Left(ServerFailure('Unexpected error'));
  }
}
```

---

## <a name="database-queries"></a>📊 DATABASE QUERY EXAMPLES

### Common Firebase Queries

```dart
// 1. Get user profile
final snapshot = await FirebaseDatabase.instance
  .ref('users/${uid}')
  .get();

if (snapshot.exists) {
  final userMap = snapshot.value as Map<dynamic, dynamic>;
  // Convert to object
}

// 2. Save data
await FirebaseDatabase.instance
  .ref('users/${uid}/name')
  .set('John Doe');

// 3. Update multiple fields
await FirebaseDatabase.instance
  .ref('users/${uid}')
  .update({
    'name': 'John',
    'age': 25,
  });

// 4. Delete data
await FirebaseDatabase.instance
  .ref('users/${uid}/photoUrl')
  .remove();

// 5. Listen to real-time changes
FirebaseDatabase.instance
  .ref('users/${uid}/exp')
  .onValue
  .listen((event) {
    final exp = event.snapshot.value;
    // Update UI
  });

// 6. Query with ordering
final snapshot = await FirebaseDatabase.instance
  .ref('users')
  .orderByChild('exp')
  .limitToLast(10) // Top 10
  .get();

// 7. Batch write
final updates = <String, dynamic>{
  'users/$uid1/name': 'User 1',
  'users/$uid2/name': 'User 2',
};

await FirebaseDatabase.instance
  .ref()
  .update(updates);
```

---

**End of Advanced Documentation**

*Untuk informasi lebih lanjut, baca kode source dan Firebase documentation*
