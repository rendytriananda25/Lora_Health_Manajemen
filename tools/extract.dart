import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('lib/features/dashboard/data/nutrition_data.dart');
  final content = file.readAsStringSync();
  
  final regex = RegExp(r'"name":\s*"([^"]+)"');
  final matches = regex.allMatches(content);
  final Set<String> foods = {};
  
  for (var m in matches) {
    foods.add(m.group(1)!);
  }

  print("Found ${foods.length} foods!");
  
  // Dump to a JSON file so I can read it easily
  File('foods_list.json').writeAsStringSync(jsonEncode(foods.toList()));
  print("Saved to foods_list.json");
}
