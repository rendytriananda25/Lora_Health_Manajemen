import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'core/services/language_provider.dart';
import 'core/services/theme_provider.dart';
import 'features/notification/notification_service.dart';
import 'features/notification/workout_reminder_service.dart';
import 'screen/navbar.dart';
import 'screen/onboarding_screen.dart';
import 'setup/setup_page.dart';
import 'features/dashboard/data/nutrition_data.dart';
import 'features/map/data/workout_data.dart';
// ✅ Clean Architecture: Dashboard
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/dashboard/domain/usecases/get_weather_data.dart';
import 'features/dashboard/domain/usecases/get_user_profile.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/data/datasources/weather_remote_datasource.dart';
import 'features/dashboard/data/datasources/user_remote_datasource.dart';
// ✅ Clean Architecture: Workout
import 'features/workout/presentation/providers/workout_provider.dart';
import 'features/workout/data/repositories/workout_repository_impl.dart';
import 'features/workout/data/datasources/workout_remote_datasource.dart';
// ✅ Clean Architecture: History
import 'features/history/presentation/providers/history_provider.dart';
import 'features/history/domain/usecases/get_history_stream.dart';
import 'features/history/domain/usecases/delete_history_item.dart';
import 'features/history/data/repositories/history_repository_impl.dart';
import 'features/history/data/datasources/history_remote_datasource.dart';
// ✅ Clean Architecture: BMI
import 'features/bmi/presentation/providers/bmi_provider.dart';
import 'features/bmi/domain/usecases/calculate_bmi.dart';
import 'features/bmi/domain/usecases/save_bmi_history.dart';
import 'features/bmi/data/repositories/bmi_repository_impl.dart';
import 'features/bmi/data/datasources/bmi_remote_datasource.dart';
// ✅ Clean Architecture: Statistics
import 'features/statistics/presentation/providers/stats_provider.dart';
import 'features/statistics/data/repositories/stats_repository_impl.dart';
import 'features/statistics/data/datasources/stats_remote_datasource.dart';
// ✅ Clean Architecture: Settings
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/settings/domain/usecases/get_user_profile.dart' as settings_uc;
import 'features/settings/domain/usecases/update_user_name.dart' as settings_uc;
import 'features/settings/domain/usecases/save_local_photo.dart' as settings_uc;
import 'features/settings/domain/usecases/logout_user.dart' as settings_uc;
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/data/datasources/settings_remote_datasource.dart';
import 'features/settings/data/datasources/settings_local_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();
  debugPrint("🚀 Main: Theme Initialized");
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  await WorkoutReminderService.instance.initDefault();
  NutritionData.fetchFromFirebase();
  WorkoutData.fetchFromFirebase();

  // ✅ Clean Architecture: Setup Dashboard Dependencies
  final weatherDataSource = WeatherRemoteDataSource();
  final userDataSource = UserRemoteDataSource();
  final dashboardRepo = DashboardRepositoryImpl(
    weatherDataSource: weatherDataSource,
    userDataSource: userDataSource,
  );

  // ✅ Clean Architecture: Setup Workout Dependencies
  final workoutDataSource = WorkoutRemoteDataSource();
  final workoutRepo = WorkoutRepositoryImpl(dataSource: workoutDataSource);

  // ✅ Clean Architecture: Setup History Dependencies
  final historyDataSource = HistoryRemoteDataSource();
  final historyRepo = HistoryRepositoryImpl(remoteDataSource: historyDataSource);

  // ✅ Clean Architecture: Setup BMI Dependencies
  final bmiDataSource = BmiRemoteDataSource();
  final bmiRepo = BmiRepositoryImpl(remoteDataSource: bmiDataSource);

  // ✅ Clean Architecture: Setup Statistics Dependencies
  final statsDataSource = StatsRemoteDataSource();
  final statsRepo = StatsRepositoryImpl(dataSource: statsDataSource);

  // ✅ Clean Architecture: Setup Settings Dependencies
  final settingsRemoteDataSource = SettingsRemoteDataSource();
  final settingsLocalDataSource = SettingsLocalDataSource();
  final settingsRepo = SettingsRepositoryImpl(
    remoteDataSource: settingsRemoteDataSource,
    localDataSource: settingsLocalDataSource,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        // ✅ Dashboard Provider (Clean Architecture)
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(
            getWeatherData: GetWeatherData(dashboardRepo),
            getUserProfile: GetUserProfile(dashboardRepo),
            repository: dashboardRepo,
          ),
        ),
        // ✅ Workout Provider (Clean Architecture)
        ChangeNotifierProvider(
          create: (_) => WorkoutProvider(
            repository: workoutRepo,
          ),
        ),
        // ✅ History Provider (Clean Architecture)
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(
            getHistoryStream: GetHistoryStream(historyRepo),
            deleteHistoryItem: DeleteHistoryItem(historyRepo),
          ),
        ),
        // ✅ BMI Provider (Clean Architecture)
        ChangeNotifierProvider(
          create: (_) => BmiProvider(
            calculateBmi: CalculateBmi(),
            saveBmiHistory: SaveBmiHistory(bmiRepo),
          ),
        ),
        // ✅ Statistics Provider (Clean Architecture)
        ChangeNotifierProvider(
          create: (_) => StatsProvider(
            repository: statsRepo,
          ),
        ),
        // ✅ Settings Provider (Clean Architecture)
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            getUserProfile: settings_uc.GetUserProfile(settingsRepo),
            updateUserName: settings_uc.UpdateUserName(settingsRepo),
            saveLocalPhoto: settings_uc.SaveLocalPhoto(settingsRepo),
            logoutUser: settings_uc.LogoutUser(settingsRepo),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final String dbUrl =
      "https://lora-1-b0d0c-default-rtdb.asia-southeast1.firebasedatabase.app";

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lora Assistant',
      theme: themeProvider.themeData,
      home: Builder(
        builder: (context) {
          final isDark = themeProvider.isDarkMode;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: themeProvider.bgColor,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );

          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: themeProvider.bgColor, // Use Theme Color
                  body: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF008BFF)),
                  ),
                );
              }
              if (authSnapshot.hasData && authSnapshot.data != null) {
                final user = authSnapshot.data!;
                return FutureBuilder<DataSnapshot>(
                  future:
                      FirebaseDatabase.instanceFor(
                            app: FirebaseAuth.instance.app,
                            databaseURL: dbUrl,
                          )
                          .ref("users/${user.uid}/favorite_sports")
                          .get()
                          .timeout(const Duration(seconds: 10)),
                  builder: (context, dbSnapshot) {
                    if (dbSnapshot.connectionState == ConnectionState.waiting) {
                      return Scaffold(
                        backgroundColor: themeProvider.bgColor,
                        body: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF008BFF),
                          ),
                        ),
                      );
                    }
                    if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                      return const Navbar();
                    }
                    return const SetupPage();
                  },
                );
              }
              return const OnboardingScreen();
            },
          );
        },
      ),
    );
  }
}
