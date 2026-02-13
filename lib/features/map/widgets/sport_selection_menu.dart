import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lora_1/core/services/language_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Positioned(
      top: 110,
      left: 20,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white12),
        ),
        child: mySports.isEmpty
            ? Center(
                child: Text(
                  lang.translate('map.loadingData'),
                  style: const TextStyle(color: Colors.white54),
                ),
              )
            : Column(
                children: mySports.map((sportName) {
                  return ListTile(
                    leading: Icon(
                      _getIconForSport(sportName),
                      color: Colors.white,
                    ),
                    title: Text(
                      sportName,
                      style: const TextStyle(
                        color: Colors.white,
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
