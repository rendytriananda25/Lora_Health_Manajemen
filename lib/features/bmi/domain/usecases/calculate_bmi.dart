import 'package:lora_1/features/bmi/domain/entities/bmi_result_entity.dart';

class CalculateBmi {
  BmiResultEntity call({required int weightKg, required int heightCm}) {
    double heightInMeter = heightCm / 100;
    double score = weightKg / (heightInMeter * heightInMeter);
    
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

    return BmiResultEntity(score: score, status: status, colorHex: colorHex);
  }
}
