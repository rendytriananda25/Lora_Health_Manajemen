import 'package:lora_1/core/services/language_provider.dart';

class FoodTranslator {
  static String translateName(String indonesianName, LanguageProvider lang) {
    if (lang.currentLanguage == 'id') return indonesianName;
    
    switch (indonesianName) {
      case "Putih Telur": return lang.currentLanguage == 'en' ? "Egg Whites" : lang.currentLanguage == 'es' ? "Claras de Huevo" : "卵白";
      case "Telur Rebus": return lang.currentLanguage == 'en' ? "Boiled Egg" : lang.currentLanguage == 'es' ? "Huevo Hervido" : "ゆで卵";
      case "Dada Ayam Rebus": return lang.currentLanguage == 'en' ? "Boiled Chicken Breast" : lang.currentLanguage == 'es' ? "Pechuga de Pollo Hervida" : "茹で鶏胸肉";
      case "Ikan Kukus": return lang.currentLanguage == 'en' ? "Steamed Fish" : lang.currentLanguage == 'es' ? "Pescado al Vapor" : "蒸し魚";
      case "Tahu Kukus": return lang.currentLanguage == 'en' ? "Steamed Tofu" : lang.currentLanguage == 'es' ? "Tofu al Vapor" : "蒸し豆腐";
      case "Tempe Panggang": return lang.currentLanguage == 'en' ? "Roasted Tempeh" : lang.currentLanguage == 'es' ? "Tempeh Asado" : "テンペのロースト";
      case "Sayur Bayam": return lang.currentLanguage == 'en' ? "Spinach" : lang.currentLanguage == 'es' ? "Espinacas" : "ほうれん草";
      case "Sayur Kangkung": return lang.currentLanguage == 'en' ? "Water Spinach" : lang.currentLanguage == 'es' ? "Espinaca de Agua" : "空芯菜";
      case "Brokoli": return lang.currentLanguage == 'en' ? "Broccoli" : lang.currentLanguage == 'es' ? "Brócoli" : "ブロッコリー";
      case "Lalapan": return lang.currentLanguage == 'en' ? "Fresh Veggies" : lang.currentLanguage == 'es' ? "Verduras Frescas" : "生野菜";
      case "Gado-gado (No Lontong)": return lang.currentLanguage == 'en' ? "Vegetable Salad (No Rice Cake)" : lang.currentLanguage == 'es' ? "Ensalada de Verduras" : "温野菜サラダ";
      case "Pecel Sayur": return lang.currentLanguage == 'en' ? "Peanut Sauce Veggies" : lang.currentLanguage == 'es' ? "Ensalada con Salsa de Maní" : "ピーナッツソース野菜";
      case "Soto Ayam (No Santan)": return lang.currentLanguage == 'en' ? "Chicken Soup (Clear)" : lang.currentLanguage == 'es' ? "Sopa de Pollo (Clara)" : "鶏肉のスープ";
      case "Sup Ayam Bening": return lang.currentLanguage == 'en' ? "Clear Chicken Soup" : lang.currentLanguage == 'es' ? "Sopa Clara de Pollo" : "澄んだ鶏スープ";
      case "Apel": return lang.currentLanguage == 'en' ? "Apple" : lang.currentLanguage == 'es' ? "Manzana" : "りんご";
      case "Pepaya": return lang.currentLanguage == 'en' ? "Papaya" : lang.currentLanguage == 'es' ? "Papaya" : "パパイヤ";
      case "Semangka": return lang.currentLanguage == 'en' ? "Watermelon" : lang.currentLanguage == 'es' ? "Sandía" : "スイカ";
      case "Teh Hijau": return lang.currentLanguage == 'en' ? "Green Tea" : lang.currentLanguage == 'es' ? "Té Verde" : "緑茶";
      case "Air Putih": return lang.currentLanguage == 'en' ? "Water" : lang.currentLanguage == 'es' ? "Agua" : "水";
      case "Air Kelapa Murni": return lang.currentLanguage == 'en' ? "Pure Coconut Water" : lang.currentLanguage == 'es' ? "Agua de Coco" : "ココナッツウォーター";
      case "Nasi Putih Besar": return lang.currentLanguage == 'en' ? "Large White Rice" : lang.currentLanguage == 'es' ? "Arroz Blanco Grande" : "白ご飯（大）";
      case "Gorengan": return lang.currentLanguage == 'en' ? "Fried Snacks" : lang.currentLanguage == 'es' ? "Frituras" : "揚げ物";
      case "Bakwan": return lang.currentLanguage == 'en' ? "Vegetable Fritter" : lang.currentLanguage == 'es' ? "Fritura de Verduras" : "野菜のかき揚げ";
      case "Martabak Manis": return lang.currentLanguage == 'en' ? "Sweet Pancake" : lang.currentLanguage == 'es' ? "Panqueque Dulce" : "甘いパンケーキ";
      case "Mie Instan": return lang.currentLanguage == 'en' ? "Instant Noodles" : lang.currentLanguage == 'es' ? "Fideos Instantáneos" : "インスタントラーメン";
      case "Rendang Berlemak": return lang.currentLanguage == 'en' ? "Fatty Beef Rendang" : lang.currentLanguage == 'es' ? "Estofado de Carne Grasa" : "脂っこいビーフレンダン";
      case "Minuman Boba": return lang.currentLanguage == 'en' ? "Boba Drink" : lang.currentLanguage == 'es' ? "Bebida de Tapioca" : "タピオカドリンク";
      case "Es Teh Manis": return lang.currentLanguage == 'en' ? "Sweet Iced Tea" : lang.currentLanguage == 'es' ? "Té Helado Dulce" : "甘いアイスティ";
      case "Soda": return lang.currentLanguage == 'en' ? "Soda" : lang.currentLanguage == 'es' ? "Refresco" : "ソーダ";
      case "Kue Kering": return lang.currentLanguage == 'en' ? "Cookies" : lang.currentLanguage == 'es' ? "Galletas" : "クッキー";
      case "Daging Sapi": return lang.currentLanguage == 'en' ? "Beef" : lang.currentLanguage == 'es' ? "Carne de Res" : "牛肉";
      case "Ayam Panggang": return lang.currentLanguage == 'en' ? "Grilled Chicken" : lang.currentLanguage == 'es' ? "Pollo Asado" : "グリルチキン";
      case "Telur Utuh": return lang.currentLanguage == 'en' ? "Whole Egg" : lang.currentLanguage == 'es' ? "Huevo Entero" : "全卵";
      case "Ikan Tuna": return lang.currentLanguage == 'en' ? "Tuna" : lang.currentLanguage == 'es' ? "Atún" : "ツナ";
      case "Ikan Salmon": return lang.currentLanguage == 'en' ? "Salmon" : lang.currentLanguage == 'es' ? "Salmón" : "サーモン";
      case "Tempe": return lang.currentLanguage == 'en' ? "Tempeh" : lang.currentLanguage == 'es' ? "Tempeh" : "テンペ";
      case "Tahu": return lang.currentLanguage == 'en' ? "Tofu" : lang.currentLanguage == 'es' ? "Tofu" : "豆腐";
      case "Nasi Merah": return lang.currentLanguage == 'en' ? "Brown Rice" : lang.currentLanguage == 'es' ? "Arroz Integral" : "玄米";
      case "Ubi Rebus": return lang.currentLanguage == 'en' ? "Boiled Sweet Potato" : lang.currentLanguage == 'es' ? "Camote Hervido" : "茹でサツマイモ";
      case "Kentang Rebus": return lang.currentLanguage == 'en' ? "Boiled Potato" : lang.currentLanguage == 'es' ? "Papa Hervida" : "茹でジャガイモ";
      case "Oatmeal": return lang.currentLanguage == 'en' ? "Oatmeal" : lang.currentLanguage == 'es' ? "Avena" : "オートミール";
      case "Susu Full Cream": return lang.currentLanguage == 'en' ? "Full Cream Milk" : lang.currentLanguage == 'es' ? "Leche Entera" : "全乳";
      case "Whey/Susu Protein": return lang.currentLanguage == 'en' ? "Whey Protein" : lang.currentLanguage == 'es' ? "Proteína Whey" : "ホエイプロテイン";
      case "Kacang Tanah": return lang.currentLanguage == 'en' ? "Peanuts" : lang.currentLanguage == 'es' ? "Maní" : "ピーナッツ";
      case "Almond": return lang.currentLanguage == 'en' ? "Almonds" : lang.currentLanguage == 'es' ? "Almendras" : "アーモンド";
      case "Selai Kacang": return lang.currentLanguage == 'en' ? "Peanut Butter" : lang.currentLanguage == 'es' ? "Mantequilla de Maní" : "ピーナッツバター";
      case "Alkohol": return lang.currentLanguage == 'en' ? "Alcohol" : lang.currentLanguage == 'es' ? "Alcohol" : "アルコール";
      case "Keripik": return lang.currentLanguage == 'en' ? "Chips" : lang.currentLanguage == 'es' ? "Papas Fritas" : "ポテトチップス";
      case "Gula Berlebih": return lang.currentLanguage == 'en' ? "Excess Sugar" : lang.currentLanguage == 'es' ? "Exceso de Azúcar" : "過剰な砂糖";
      case "Fast Food": return lang.currentLanguage == 'en' ? "Fast Food" : lang.currentLanguage == 'es' ? "Comida Rápida" : "ファストフード";
      case "Buah Campur": return lang.currentLanguage == 'en' ? "Mixed Fruits" : lang.currentLanguage == 'es' ? "Frutas Mixtas" : "ミックスフルーツ";
      case "Ikan Bakar": return lang.currentLanguage == 'en' ? "Grilled Fish" : lang.currentLanguage == 'es' ? "Pescado Asado" : "焼き魚";
      case "Sup Sayur": return lang.currentLanguage == 'en' ? "Vegetable Soup" : lang.currentLanguage == 'es' ? "Sopa de Verduras" : "野菜スープ";
      case "Capcay": return lang.currentLanguage == 'en' ? "Stir-fried Veggies" : lang.currentLanguage == 'es' ? "Verduras Salteadas" : "野菜炒め";
      case "Yoghurt Plain": return lang.currentLanguage == 'en' ? "Plain Yogurt" : lang.currentLanguage == 'es' ? "Yogur Natural" : "プレーンヨーグルト";
      case "Air Kelapa": return lang.currentLanguage == 'en' ? "Coconut Water" : lang.currentLanguage == 'es' ? "Agua de Coco" : "ココナッツウォーター";
      case "Smoothie (No Gula)": return lang.currentLanguage == 'en' ? "Smoothie (No Sugar)" : lang.currentLanguage == 'es' ? "Batido (Sin Azúcar)" : "スムージー（砂糖なし）";
      case "Asin Berlebih": return lang.currentLanguage == 'en' ? "Excessive Salt" : lang.currentLanguage == 'es' ? "Exceso de Sal" : "塩分の摂りすぎ";
      case "Margarin": return lang.currentLanguage == 'en' ? "Margarine" : lang.currentLanguage == 'es' ? "Margarina" : "マーガリン";
      case "Jeroan": return lang.currentLanguage == 'en' ? "Offal" : lang.currentLanguage == 'es' ? "Menudencias" : "内臓肉";
      default: return indonesianName;
    }
  }

  static String translateMealTime(String indonesianMealTime, LanguageProvider lang) {
    if (lang.currentLanguage == 'id') return indonesianMealTime;
    switch (indonesianMealTime) {
      case "SARAPAN": return lang.currentLanguage == 'en' ? "BREAKFAST" : lang.currentLanguage == 'es' ? "DESAYUNO" : "朝食";
      case "MAKAN SIANG": return lang.currentLanguage == 'en' ? "LUNCH" : lang.currentLanguage == 'es' ? "ALMUERZO" : "昼食";
      case "MAKAN MALAM": return lang.currentLanguage == 'en' ? "DINNER" : lang.currentLanguage == 'es' ? "CENA" : "夕食";
      default: return indonesianMealTime;
    }
  }

  static String translateGoalReason(String idReason, LanguageProvider lang) {
    if (lang.currentLanguage == 'id') return idReason;
    switch (idReason) {
      case "Rendah kalori, tinggi serat & protein.": return lang.currentLanguage == 'en' ? "Low calorie, high fiber & protein." : lang.currentLanguage == 'es' ? "Bajo en calorías, alto en fibra y proteínas." : "低カロリー、高食物繊維＆タンパク質。";
      case "Tinggi gula, tepung olahan & lemak jenuh.": return lang.currentLanguage == 'en' ? "High sugar, refined carbs & sat fats." : lang.currentLanguage == 'es' ? "Alto en azúcar y grasas saturadas." : "高糖分、精製炭水化物、飽和脂肪。";
      case "Protein tinggi & kalori berkualitas untuk otot.": return lang.currentLanguage == 'en' ? "High protein & quality calories for muscle." : lang.currentLanguage == 'es' ? "Alta proteína y calorías de calidad." : "筋肉のための高タンパクと良質なカロリー。";
      case "Menghambat recovery & sintesis protein.": return lang.currentLanguage == 'en' ? "Hinders recovery & protein synthesis." : lang.currentLanguage == 'es' ? "Dificulta la recuperación y síntesis de proteínas." : "回復とタンパク質合成を妨げる。";
      case "Nutrisi seimbang untuk stamina & kesehatan jangka panjang.": return lang.currentLanguage == 'en' ? "Balanced nutrition for stamina & health." : lang.currentLanguage == 'es' ? "Nutrición equilibrada para la salud." : "スタミナと長期的な健康のためのバランスの取れた栄養。";
      case "Memicu penyakit metabolik & inflamasi.": return lang.currentLanguage == 'en' ? "Triggers metabolic disease & inflammation." : lang.currentLanguage == 'es' ? "Desencadena enfermedades metabólicas e inflamación." : "代謝性疾患と炎症を引き起こす。";
      default: return idReason;
    }
  }
}
