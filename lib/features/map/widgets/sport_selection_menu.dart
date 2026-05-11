import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';
import 'package:lora_1/core/services/theme_provider.dart';

class SportSelectionMenu extends StatelessWidget {
  final List<String> mySports;
  final Function(String) onSelect;

  const SportSelectionMenu({
    super.key,
    required this.mySports,
    required this.onSelect,
  });

  IconData _getIconForSport(String sport) {
    switch (sport) {
      case "Lari":
        return Icons.directions_run;
      case "Sepeda":
        return Icons.directions_bike;
      case "Home Workout":
        return Icons.fitness_center;
      case "Basket":
        return Icons.sports_basketball;
      case "Sepak Bola":
        return Icons.sports_soccer;
      default:
        return Icons.sports;
    }
  }

  String _translateSport(String sport, LanguageProvider lang) {
    if (lang.currentLanguage == 'id') return sport;
    switch (sport) {
      case "Lari": return lang.currentLanguage == 'en' ? "Running" : lang.currentLanguage == 'es' ? "Correr" : "ランニング";
      case "Sepeda": return lang.currentLanguage == 'en' ? "Cycling" : lang.currentLanguage == 'es' ? "Ciclismo" : "サイクリング";
      case "Basket": return lang.currentLanguage == 'en' ? "Basketball" : lang.currentLanguage == 'es' ? "Baloncesto" : "バスケットボール";
      case "Sepak Bola": return lang.currentLanguage == 'en' ? "Football" : lang.currentLanguage == 'es' ? "Fútbol" : "サッカー";
      case "Bola": return lang.currentLanguage == 'en' ? "Football" : lang.currentLanguage == 'es' ? "Fútbol" : "サッカー";
      case "Home Workout": return lang.currentLanguage == 'ja' ? "ホームワークアウト" : sport;
      default: return sport;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    return Positioned(
      top: 110,
      left: 20,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.boxColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: theme.textColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: mySports.isEmpty
            ? Center(
                child: Text(
                  lang.translate('map.loadingData'),
                  style: TextStyle(color: theme.textColor.withOpacity(0.54)),
                ),
              )
            : Column(
                children: mySports.map((sportName) {
                  return ListTile(
                    leading: Icon(
                      _getIconForSport(sportName),
                      color: theme.textColor,
                    ),
                    title: Text(
                      _translateSport(sportName, lang),
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => onSelect(sportName),
                  );
                }).toList(),
              ),
      ),
    );
  }
}
