import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/core/utils/app_size.dart';
import 'package:lora_1/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:lora_1/features/dashboard/widgets/glass_card.dart';
import 'package:lora_1/features/dashboard/widgets/dashboard_header.dart';
import 'package:lora_1/features/dashboard/widgets/nutrition_carousel.dart';
import 'package:lora_1/features/dashboard/data/food_translator.dart';
import 'package:lora_1/features/settings/presentation/pages/setting_page.dart';
import 'package:lora_1/features/statistics/presentation/pages/statistics_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey rankIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.init().then((_) {
        if (mounted) _checkDailyLogin(provider);
      });
    });
  }

  String _lastLangCode = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final langService = Provider.of<LanguageProvider>(context);
    if (_lastLangCode != langService.currentLanguage) {
      if (_lastLangCode.isNotEmpty) {
        final provider = Provider.of<DashboardProvider>(context, listen: false);
        final langCode = langService.currentLanguage;
        Future.microtask(() {
          provider.loadWeather(langCode: langCode);
          provider.clearDailyPlan();
        });
      }
      _lastLangCode = langService.currentLanguage;
    }
  }

  Future<void> _checkDailyLogin(DashboardProvider provider) async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    int gained = await provider.checkDailyLogin();
    if (gained > 0 && mounted) {
      _showFlyingExp(gained);
    }
  }

  void _showFlyingExp(int amount) {
    Offset targetPos = Offset(
      MediaQuery.of(context).size.width - 50,
      60,
    );
    final RenderBox? targetBox =
        rankIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox != null) {
      targetPos = targetBox.localToGlobal(Offset.zero);
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 0, top: 0, right: 0, bottom: 0,
          child: _DailyLoginOverlay(
            endPos: targetPos,
            amount: amount,
            onFinished: () {
              if (entry.mounted) entry.remove();
            },
          ),
        );
      },
    );
    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final dashboard = Provider.of<DashboardProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    var aqiInfo = dashboard.getAQIDetail(lang.translate);
    var uvInfo = dashboard.getUVDetail(lang.translate);

    final recommendations = dashboard.getRecommendations(translate: lang.translate);

    final foodList = dashboard.getFoodList(
      translateName: (name) => FoodTranslator.translateName(name, lang),
      translateGoalReason: (reason) => FoodTranslator.translateGoalReason(reason, lang),
    );

    if (dashboard.dailyPlan.isEmpty && foodList.isNotEmpty) {
      Future.microtask(() {
        dashboard.generateDailyPlanFromFoods(foodList);
      });
    }

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: false),
              child: RefreshIndicator(
                onRefresh: dashboard.refresh,
                color: const Color(0xFF008BFF),
                backgroundColor: theme.boxColor,
                edgeOffset: AppSize.h(120),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSize.w(20), AppSize.h(140),
                    AppSize.w(20), AppSize.h(150),
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeatherCard(dashboard, recommendations, theme),
                      SizedBox(height: AppSize.h(30)),
                      Text(
                        lang.translate('dashboard.environmentStatus'),
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: AppSize.sp(17),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppSize.h(15)),
                      Row(
                        children: [
                          _buildStatCard(
                            lang.translate('dashboard.airQuality'),
                            aqiInfo['status'], Icons.air,
                            aqiInfo['color'], theme,
                          ),
                          SizedBox(width: AppSize.w(15)),
                          _buildStatCard(
                            lang.translate('dashboard.uvIndex'),
                            uvInfo['status'], Icons.sunny,
                            uvInfo['color'], theme,
                          ),
                        ],
                      ),
                      SizedBox(height: AppSize.h(25)),
                      _buildTipsCard(
                        dashboard.weather.city == 'Memuat Lokasi...' ||
                                dashboard.weather.city == 'Koneksi Gagal'
                            ? lang.translate('dashboard.preparingTips')
                            : "${aqiInfo['tips']} ${uvInfo['tips']}",
                        lang, theme,
                      ),
                      SizedBox(height: AppSize.h(30)),
                      _buildDailyMealPlan(dashboard, theme, lang),
                      SizedBox(height: AppSize.h(30)),
                      NutritionCarousel(
                        userGoal: dashboard.userProfile.fitnessGoal,
                        allFoods: foodList,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 0, left: 0, right: 0,
            child: DashboardHeader(
              userName: dashboard.userProfile.name,
              localPhotoPath: dashboard.userProfile.localPhotoPath,
              userRank: dashboard.currentRank,
              currentExp: dashboard.currentExp,
              rankIconKey: rankIconKey,
              onProfileTap: () async {
                await Navigator.of(context).push(_createRoute());
                if (mounted) {
                  final prefs = await SharedPreferences.getInstance();
                  dashboard.updateLocalPhoto(prefs.getString('user_local_photo'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildWeatherCard(
    DashboardProvider dashboard,
    List<String> recommendations,
    ThemeProvider theme,
  ) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            dashboard.weather.city.toUpperCase(),
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.7),
                              fontSize: 12, fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${dashboard.weather.temperature}° Celsius",
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 32, fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dashboard.weather.condition.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF008BFF),
                          fontWeight: FontWeight.bold, fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 50),
              ],
            ),
            const Divider(color: Colors.white10, height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                recommendations.isNotEmpty
                    ? recommendations[dashboard.currentRecIndex % recommendations.length]
                    : "Memuat...",
                key: ValueKey<int>(dashboard.currentRecIndex),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16, fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (recommendations.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  recommendations.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dashboard.currentRecIndex == i
                          ? const Color(0xFF008BFF)
                          : theme.textColor.withOpacity(0.24),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label, String value, IconData icon, Color color, ThemeProvider theme,
  ) {
    return Expanded(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(
                color: theme.textColor.withOpacity(0.54), fontSize: 11,
              )),
              Text(value, style: TextStyle(
                color: theme.textColor, fontSize: 16, fontWeight: FontWeight.bold,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard(String tips, LanguageProvider lang, ThemeProvider theme) {
    return GlassCard(
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF008BFF),
              child: Icon(Icons.lightbulb_outline, color: Colors.white),
            ),
            title: Text(
              lang.translate('dashboard.healthTips'),
              style: TextStyle(
                color: theme.textColor, fontSize: 14, fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              tips,
              style: TextStyle(
                color: theme.textColor.withOpacity(0.7), fontSize: 12,
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          InkWell(
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const StatisticsPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lang.translate('dashboard.viewProgress'),
                    style: const TextStyle(
                      color: Color(0xFF008BFF), fontWeight: FontWeight.bold, fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward, color: Color(0xFF008BFF), size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMealPlan(
    DashboardProvider dashboard, ThemeProvider theme, LanguageProvider lang,
  ) {
    if (dashboard.dailyPlan.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('dashboard.dailyPlan'),
          style: TextStyle(
            color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: dashboard.dailyPlan.map((food) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.boxColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: theme.textColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(food.icon, color: Colors.green, size: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      FoodTranslator.translateMealTime(food.mealTime ?? 'SARAPAN', lang),
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.5),
                        fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FoodTranslator.translateName(food.rawName, lang),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      food.description,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF008BFF), fontSize: 12, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutQuart)),
          ),
          child: child,
        );
      },
    );
  }
}

class _DailyLoginOverlay extends StatefulWidget {
  final Offset endPos;
  final int amount;
  final VoidCallback onFinished;

  const _DailyLoginOverlay({
    required this.endPos,
    required this.amount,
    required this.onFinished,
  });

  @override
  State<_DailyLoginOverlay> createState() => _DailyLoginOverlayState();
}

class _DailyLoginOverlayState extends State<_DailyLoginOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  late AnimationController _flyController;
  late Animation<Offset> _flyAnim;
  late Animation<double> _flyScaleAnim;

  bool _isFlying = false;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _mainController, curve: Curves.elasticOut,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    _flyController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),
    );
    _runSequence();
  }

  void _runSequence() async {
    await _mainController.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isFlying = true);

    final Size size = MediaQuery.of(context).size;
    final Offset start = Offset(size.width / 2, size.height / 2);

    _flyAnim = Tween<Offset>(begin: start, end: widget.endPos).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeInOutBack),
    );
    _flyScaleAnim = Tween<double>(begin: 1.5, end: 0.5).animate(_flyController);

    await _flyController.forward();
    widget.onFinished();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          if (!_isFlying)
            AnimatedBuilder(
              animation: _fadeAnim,
              builder: (ctx, child) => BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 5 * _fadeAnim.value,
                  sigmaY: 5 * _fadeAnim.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.6 * _fadeAnim.value),
                ),
              ),
            ),
          if (!_isFlying)
            Center(
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "DAILY LOGIN",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white,
                        letterSpacing: 4, fontSize: 16,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.6),
                            blurRadius: 40, spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.bolt, color: Colors.amber, size: 80),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "+${widget.amount} EXP",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 48, color: Colors.white,
                        shadows: [Shadow(color: Colors.amber, blurRadius: 20)],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Terus konsisten ya! 🔥",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            AnimatedBuilder(
              animation: _flyController,
              builder: (ctx, child) {
                return Positioned(
                  left: _flyAnim.value.dx - 25,
                  top: _flyAnim.value.dy - 25,
                  child: Transform.scale(
                    scale: _flyScaleAnim.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: Colors.amber, size: 50),
                        Text(
                          "+${widget.amount}",
                          style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber,
                            shadows: [Shadow(blurRadius: 5, color: Colors.black45)],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
