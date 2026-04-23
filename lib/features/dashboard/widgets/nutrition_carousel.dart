import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';
import 'package:lora_1/core/utils/app_size.dart';

class NutritionCarousel extends StatelessWidget {
  final String userGoal;
  final List<Map<String, dynamic>> allFoods;

  const NutritionCarousel({
    super.key,
    required this.userGoal,
    required this.allFoods,
  });

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSize.w(5)),
                child: Text(
                  lang.translate('dashboard.nutritionRecommendation'),
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: AppSize.sp(17),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(width: AppSize.w(8)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w(8),
                vertical: AppSize.h(4),
              ),
              decoration: BoxDecoration(
                color: theme.textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSize.r(8)),
              ),
              child: Text(
                userGoal.replaceAll("_", " "),
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.54),
                  fontSize: AppSize.sp(10),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSize.h(15)),
        SizedBox(
          height: AppSize.h(190),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allFoods.length,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = allFoods[index];
                bool isGood = item['type'] == "good";
                return Container(
                  width: AppSize.w(270),
                  margin: EdgeInsets.only(right: AppSize.w(15)),
                  padding: EdgeInsets.all(AppSize.w(15)),
                  decoration: BoxDecoration(
                    color: theme.boxColor,
                    borderRadius: BorderRadius.circular(AppSize.r(20)),
                    border: Border.all(color: theme.textColor.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: AppSize.w(46),
                            height: AppSize.w(46),
                            decoration: BoxDecoration(
                              color: isGood
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item['icon'],
                              color: isGood ? Colors.green : Colors.redAccent,
                              size: AppSize.sp(24),
                            ),
                          ),
                          SizedBox(width: AppSize.w(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppSize.sp(15),
                                  ),
                                ),
                                SizedBox(height: AppSize.h(5)),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      Icons.star,
                                      size: AppSize.sp(13),
                                      color: starIndex < item['rating']
                                          ? Colors.orangeAccent
                                          : theme.textColor.withOpacity(0.2),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSize.h(12)),
                      Text(
                        item['desc'],
                        style: TextStyle(
                          color: theme.textColor.withOpacity(0.7),
                          fontSize: AppSize.sp(12),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSize.w(10),
                          vertical: AppSize.h(5),
                        ),
                        decoration: BoxDecoration(
                          color: isGood
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSize.r(8)),
                        ),
                        child: Text(
                          isGood
                              ? lang.translate('dashboard.highlyRecommended')
                              : lang.translate('dashboard.avoidLimit'),
                          style: TextStyle(
                            color: isGood ? Colors.green : Colors.redAccent,
                            fontSize: AppSize.sp(11),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
